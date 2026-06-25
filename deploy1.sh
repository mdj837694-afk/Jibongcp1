#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "██████╗ ██████╗     ███████╗██████╗ ███████╗███████╗"
echo "██╔══██╗██╔══██╗    ██╔════╝██╔══██╗██╔════╝██╔════╝"
echo "██████╔╝██║  ██║    █████╗  ██████╔╝█████╗  █████╗"
echo "██╔══██╗██║  ██║    ██╔══╝  ██╔══██╗██╔══╝  ██╔══╝"
echo "██████╔╝██████╔╝    ██║     ██║  ██║███████╗███████╗"
echo "╚═════╝ ╚═════╝     ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝"
echo ""
echo "██╗███╗   ██╗████████╗███████╗██████╗ ███╗   ██╗███████╗████████╗"
echo "██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔════╝╚══██╔══╝"
echo "██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██╔██╗ ██║█████╗     ██║"
echo "██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══╝     ██║"
echo "██║██║ ╚████║   ██║   ███████╗██║  ██║██║ ╚████║███████╗   ██║"
echo "╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝"
echo -e "${RESET}"
echo -e "${GREEN}vless WS Cloud Run Auto Deploy${RESET}"
echo -e "${YELLOW}Created by MD JIBON AHAMED${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo -e "${RED}[!] No project selected.${RESET}"
  read -p "Enter your project ID: " PROJECT_ID
  gcloud config set project "$PROJECT_ID"
fi

echo -e "${GREEN}[✓] Project: $PROJECT_ID${RESET}"

enable_api() {
  API=$1
  echo -e "${YELLOW}[*] Enabling $API ...${RESET}"
  gcloud services enable "$API" --project="$PROJECT_ID" >/dev/null 2>&1 || true
  echo -e "${GREEN}[✓] $API enabled/requested${RESET}"
}

enable_api run.googleapis.com
enable_api cloudbuild.googleapis.com
enable_api artifactregistry.googleapis.com
enable_api containerregistry.googleapis.com
enable_api compute.googleapis.com

if [[ "$PROJECT_ID" == qwiklabs-* ]]; then
  REGION="us-central1"
  echo -e "${GREEN}[✓] Qwiklabs detected. Region: $REGION${RESET}"
else
  read -p "Enter region [default: us-central1]: " REGION
  REGION=${REGION:-us-central1}
fi

read -p "Enter service name [default: bdfreeinternet-trojan]: " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-bdfreeinternet-trojan}

echo "[1] 1 vCPU, 1Gi RAM"
echo "[2] 1 vCPU, 2Gi RAM"
echo "[3] 2 vCPU, 2Gi RAM"
echo "[4] 2 vCPU, 4Gi RAM  (recommended)"
echo "[5] 4 vCPU, 8Gi RAM"
echo "[6] 4 vCPU, 16Gi RAM"
read -p "Select configuration [1-6] [default: 4]: " CHOICE
CHOICE=${CHOICE:-4}

case $CHOICE in
  1) CPU=1; MEMORY="1Gi" ;;
  2) CPU=1; MEMORY="2Gi" ;;
  3) CPU=2; MEMORY="2Gi" ;;
  4) CPU=2; MEMORY="4Gi" ;;
  5) CPU=4; MEMORY="8Gi" ;;
  6) CPU=4; MEMORY="16Gi" ;;
  *) CPU=2; MEMORY="4Gi" ;;
esac

IMAGE="gcr.io/$PROJECT_ID/$SERVICE_NAME"

gcloud builds submit --tag "$IMAGE" --project="$PROJECT_ID"

gcloud run deploy "$SERVICE_NAME" \
  --image "$IMAGE" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --cpu "$CPU" \
  --memory "$MEMORY" \
  --timeout 3600 \
  --min-instances 0 \
  --max-instances 1 \
  --project "$PROJECT_ID"

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --format='value(status.url)')

HOST=$(echo "$SERVICE_URL" | sed 's|https://||')

PASSWORD="BD-FREE-INTERNET"
WS_PATH="/Telegram/Channel/link/@BD_FREE_INTERNET"
ENCODED_PATH="%2FTelegram%2FChannel%2Flink%2F@BD_FREE_INTERNET"
SNI="firebase-settings.crashlytics.com"

TROJAN_LINK="trojan://${PASSWORD}@${HOST}:443?security=tls&type=ws&path=${ENCODED_PATH}&host=${HOST}&sni=${SNI}#${SERVICE_NAME}"

echo ""
echo -e "${GREEN}${BOLD}DEPLOYMENT SUCCESSFUL${RESET}"
echo "================================"
echo "Service:   $SERVICE_NAME"
echo "Address:   www.gstatic.com"
echo "SNI:       $SNI"
echo "Host:      $HOST"
echo "Port:      443"
echo "Password:  $PASSWORD"
echo "WS Path:   $WS_PATH"
echo "Transport: WebSocket"
echo "Security:  TLS"
echo "Protocol:  vless WS"
echo "Region:    $REGION"
echo "CPU:       $CPU"
echo "Memory:    $MEMORY"
echo "================================"
echo ""
echo "Import URI:"
echo "$TROJAN_LINK"
echo ""

echo "$TROJAN_LINK" > /tmp/vless-url.txt
echo -e "${GREEN}[✓] URI saved to: /tmp/vless-url.txt${RESET}"

echo ""
echo "[1] Show Trojan URI"
echo "[2] Start background monitor"
echo "[3] Both"
echo "[4] Exit"
read -p "Select option [1-4]: " OPTION

if [ "$OPTION" = "1" ]; then
  cat /tmp/trojan-url.txt
elif [ "$OPTION" = "2" ]; then
  chmod +x network-monitor.sh 2>/dev/null || true
  nohup ./network-monitor.sh "$SERVICE_NAME" "$REGION" >/tmp/network-monitor.log 2>&1 &
  echo -e "${GREEN}[✓] Monitor started${RESET}"
elif [ "$OPTION" = "3" ]; then
  cat /tmp/trojan-url.txt
  chmod +x network-monitor.sh 2>/dev/null || true
  nohup ./network-monitor.sh "$SERVICE_NAME" "$REGION" >/tmp/network-monitor.log 2>&1 &
  echo -e "${GREEN}[✓] Monitor started${RESET}"
else
  echo "Exit."
fi

echo ""
echo -e "${GREEN}${BOLD}DEPLOYMENT COMPLETE${RESET}"