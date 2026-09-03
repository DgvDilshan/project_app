import os
import torch
import torch.nn as nn
from torchvision import models
import onnx

class HybridResNetTransformer(nn.Module):
    def __init__(self, num_classes, d_model=256, nhead=8, num_layers=2,
                 dim_feedforward=512, dropout=0.3, backbone_dim=2048,
                 num_tokens=49):
        super(HybridResNetTransformer, self).__init__()

        try:
            resnet = models.resnet50(weights=models.ResNet50_Weights.DEFAULT)
        except AttributeError:
            resnet = models.resnet50(pretrained=True)

        for param in resnet.parameters():
            param.requires_grad = False
        for param in resnet.layer3.parameters():
            param.requires_grad = True
        for param in resnet.layer4.parameters():
            param.requires_grad = True

        self.backbone = nn.Sequential(
            resnet.conv1,
            resnet.bn1,
            resnet.relu,
            resnet.maxpool,
            resnet.layer1,
            resnet.layer2,
            resnet.layer3,
            resnet.layer4
        )

        self.proj = nn.Conv2d(backbone_dim, d_model, kernel_size=1)

        self.pos_embed = nn.Parameter(torch.zeros(1, num_tokens, d_model))
        nn.init.trunc_normal_(self.pos_embed, std=0.02)

        encoder_layers = nn.TransformerEncoderLayer(
            d_model=d_model, nhead=nhead, dim_feedforward=dim_feedforward,
            dropout=dropout, batch_first=True, norm_first=True, activation='gelu'
        )
        self.transformer_encoder = nn.TransformerEncoder(encoder_layers, num_layers=num_layers)
        self.norm = nn.LayerNorm(d_model)

        self.fc = nn.Sequential(
            nn.Linear(d_model, 256),
            nn.ReLU(),
            nn.Dropout(p=dropout),
            nn.Linear(256, num_classes)
        )

    def forward(self, x):
        features = self.backbone(x)
        features = self.proj(features)
        
        # Manually flatten and transpose instead of using features.flatten(2).transpose(1, 2)
        # to ensure ONNX compatibility
        B, C, H, W = features.shape
        tokens = features.view(B, C, H * W).transpose(1, 2)
        
        if tokens.size(1) == self.pos_embed.size(1):
            tokens = tokens + self.pos_embed

        encoded = self.transformer_encoder(tokens)
        pooled = self.norm(encoded).mean(dim=1)
        return self.fc(pooled)

def main():
    print("Loading PyTorch model...")
    device = torch.device("cpu")
    
    labels_file = r"d:\Project\Final_Project\project_app\assets\models\labels.txt"
    if os.path.exists(labels_file):
        with open(labels_file, "r") as f:
            classes = [line.strip() for line in f if line.strip()]
        num_classes = len(classes)
    else:
        num_classes = 5
    
    print(f"Num classes determined as: {num_classes}")
    
    model = HybridResNetTransformer(num_classes=num_classes)
    
    model_path = r"d:\Project\Final_Project\new_dataset\hybrid_resnet_transformer.pth"
    model.load_state_dict(torch.load(model_path, map_location=device))
    model.eval()
    
    print("Exporting to ONNX...")
    dummy_input = torch.randn(1, 3, 224, 224)
    onnx_path = "model.onnx"
    torch.onnx.export(
        model, 
        dummy_input, 
        onnx_path, 
        export_params=True,
        opset_version=13,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
    )
    print(f"ONNX export complete! Saved to {onnx_path}")

if __name__ == '__main__':
    main()
