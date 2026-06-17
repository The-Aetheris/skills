#!/bin/bash

# Model Switcher Quick Script for Hermes Agent
# Usage: ./switch-model.sh [high|medium|low] [custom|9router|deepseek]

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Current profile detection
PROFILE_NAME=$(basename $(realpath ~/.hermes/profiles/active 2>/dev/null) || echo "xenna")
PROFILE_PATH="/Users/athallarizky/.hermes/profiles/$PROFILE_NAME"

echo -e "${BLUE}🔄 Hermes Model Switcher${NC}"
echo "Profile: $PROFILE_NAME"
echo "Profile Path: $PROFILE_PATH"
echo

if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage: $0 [high|medium|low] [provider]${NC}"
    echo "Examples:"
    echo "  $0 high        # Switch to high-thinking (custom provider)"
    echo "  $0 medium      # Switch to medium-thinking (custom provider)"
    echo "  $0 low         # Switch to low-thinking (custom provider)"
    echo "  $0 high 9router # Switch to high-thinking via 9router"
    echo "  $0 low custom  # Switch to low-thinking via custom provider"
    exit 1
fi

MODEL=$1
PROVIDER=${2:-custom}

# Validate model
if [[ ! "$MODEL" =~ ^(high|medium|low)$ ]]; then
    echo -e "${RED}❌ Invalid model. Use: high, medium, or low${NC}"
    exit 1
fi

# Validate provider
if [[ ! "$PROVIDER" =~ ^(custom|9router|deepseek)$ ]]; then
    echo -e "${RED}❌ Invalid provider. Use: custom, 9router, or deepseek${NC}"
    exit 1
fi

echo -e "${GREEN}📍 Target: $MODEL-thinking via $PROVIDER${NC}"
echo

# Backup current config
echo -e "${YELLOW}📄 Backup current config...${NC}
cp "$PROFILE_PATH/config.yaml" "$PROFILE_PATH/config.yaml.backup.$(date +%Y%m%d_%H%M%S)"

# Show current config
echo -e "${BLUE}📊 Current configuration:${NC}"
hermes model show

# Execute switch command
echo -e "${YELLOW}⚡ Switching to $MODEL-thinking...${NC}"
if [ "$PROVIDER" = "9router" ]; then
    # Special handling for 9router (base_url same as custom)
    hermes model "$MODEL-thinking" --provider custom
    echo -e "${GREEN}✅ Switched to $MODEL-thinking (via 9router routing)${NC}"
elif [ "$PROVIDER" = "custom" ]; then
    hermes model "$MODEL-thinking" --provider custom
    echo -e "${GREEN}✅ Switched to $MODEL-thinking (custom provider)${NC}"
else
    hermes model "$MODEL-thinking" --provider "$PROVIDER"
    echo -e "${Green}✅ Switched to $MODEL-thinking ($PROVIDER provider)${NC}"
fi

# Verify the change
echo -e "${BLUE}🔍 Verifying configuration...${NC}"
hermes model show

echo
echo -e "${YELLOW}⚠️  CRITICAL: Session restart required!${NC}"
echo "Run: ${BLUE}/new${NC} or ${BLUE}hermes gateway restart${NC}"
echo
echo -e "${GREEN}🎯 Model switch completed successfully!${NC}"