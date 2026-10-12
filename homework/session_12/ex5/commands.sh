#!/usr/bin/env bash
# ==============================================================================
# DevOps IT209 - Session 12 - Bài 5 (EX5)
# Chẩn đoán và khắc phục 3 sự cố đứt gãy Pipeline CI/CD thực tế
# Học viên: Nguyễn Quang Vinh (Vinh Nguyen)
# Repository: QuangVinh1605/IT209-SS12-CAU5
# ==============================================================================

set -eo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

REPO="QuangVinh1605/IT209-SS12-CAU5"

echo -e "${BLUE}=====================================================================${NC}"
echo -e "${GREEN}      DevOps IT209 - Session 12 - Bài 5 (EX5)                         ${NC}"
echo -e "${GREEN}  Chẩn đoán & Khắc phục 3 sự cố đứt gãy Pipeline CI/CD thực tế         ${NC}"
echo -e "${BLUE}=====================================================================${NC}\n"

echo -e "${YELLOW}[BƯỚC 1] Lịch sử 4 lần chạy trên GitHub Actions (Từ lỗi đến sửa thành công):${NC}"
gh run list -R "$REPO" --limit 5

echo -e "\n${YELLOW}[BƯỚC 2] Kiểm tra chi tiết Workflow Run mới nhất sau khi sửa cả 3 lỗi:${NC}"
LATEST_RUN_ID=$(gh run list -R "$REPO" --limit 1 --json databaseId -q '.[0].databaseId')

if [ -n "$LATEST_RUN_ID" ]; then
    echo -e "${CYAN}Đang xem chi tiết Workflow Run ID: $LATEST_RUN_ID...${NC}"
    gh run view "$LATEST_RUN_ID" -R "$REPO"
fi

echo -e "\n${BLUE}=====================================================================${NC}"
echo -e "${GREEN}                HOÀN TẤT KIỂM TRA BÀI 5                              ${NC}"
echo -e "${BLUE}=====================================================================${NC}"
