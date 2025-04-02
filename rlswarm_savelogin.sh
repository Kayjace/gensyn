#!/bin/bash

#General args
ROOT=$PWD

# Load environment variables from .env file if it exists
if [ -f "$ROOT/.env" ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' "$ROOT/.env" | xargs)
fi

export PUB_MULTI_ADDRS
export PEER_MULTI_ADDRS
export HOST_MULTI_ADDRS
export IDENTITY_PATH
export CONNECT_TO_TESTNET
export ORG_ID
export HF_HUB_DOWNLOAD_TIMEOUT=120  # 2 minutes

#Check if public multi-address is given else set to default
DEFAULT_PUB_MULTI_ADDRS=""
PUB_MULTI_ADDRS=${PUB_MULTI_ADDRS:-$DEFAULT_PUB_MULTI_ADDRS}

#Check if peer multi-address is given else set to default
DEFAULT_PEER_MULTI_ADDRS="/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ" # gensyn coordinator node
PEER_MULTI_ADDRS=${PEER_MULTI_ADDRS:-$DEFAULT_PEER_MULTI_ADDRS}

#Check if host multi-address is given else set to default
DEFAULT_HOST_MULTI_ADDRS="/ip4/0.0.0.0/tcp/38331"
HOST_MULTI_ADDRS=${HOST_MULTI_ADDRS:-$DEFAULT_HOST_MULTI_ADDRS}

# Path to an RSA private key. If this path does not exist, a new key pair will be created.
# Remove this file if you want a new PeerID.
DEFAULT_IDENTITY_PATH="$ROOT"/swarm.pem
IDENTITY_PATH=${IDENTITY_PATH:-$DEFAULT_IDENTITY_PATH}

# Check if ORG_ID is already set from .env file
if [ -z "$ORG_ID" ] || [ -z "$USER_DATA_JSON" ] || [ -z "$USER_API_KEY_JSON" ]; then
    while true; do
        read -p "Would you like to connect to the Testnet? [Y/n] " yn
        yn=${yn:-Y}  # Default to "Y" if the user presses Enter
        case $yn in
            [Yy]* ) CONNECT_TO_TESTNET=True && break;;
            [Nn]* ) CONNECT_TO_TESTNET=False && break;;
            * ) echo ">>> Please answer yes or no.";;
        esac
    done

    if [ "$CONNECT_TO_TESTNET" = "True" ]; then
        # Check if we have userData and userApiKey in .env
        if [ -z "$USER_DATA_JSON" ] || [ -z "$USER_API_KEY_JSON" ]; then
            # No userData in .env, run modal_login as before
            echo "Please login to create an Ethereum Server Wallet"
            cd modal-login
            # Check if the yarn command exists; if not, install Yarn.
            source ~/.bashrc
            
            if ! command -v yarn >/dev/null 2>&1; then
                # Detect Ubuntu (including WSL Ubuntu) and install Yarn accordingly
                if grep -qi "ubuntu" /etc/os-release 2>/dev/null || uname -r | grep -qi "microsoft"; then
                    echo "Detected Ubuntu or WSL Ubuntu. Installing Yarn via apt..."
                    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
                    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
                    sudo apt update && sudo apt install -y yarn
                else
                    echo "Yarn is not installed. Installing Yarn..."
                    curl -o- -L https://yarnpkg.com/install.sh | sh
                    echo 'export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"' >> ~/.bashrc
                    source ~/.bashrc
                fi
            fi
            yarn install
            yarn dev > /dev/null 2>&1 & # Run in background and suppress output

            SERVER_PID=$!  # Store the process ID
            sleep 5
            open http://localhost:3000
            cd ..

            # Wait until both userData.json and userApiKey.json exist
            while [ ! -f "modal-login/temp-data/userData.json" ] || [ ! -f "modal-login/temp-data/userApiKey.json" ]; do
                echo "Waiting for userData.json and userApiKey.json to be created..."
                sleep 5  # Wait for 5 seconds before checking again
            done
            echo "userData.json and userApiKey.json found. Proceeding..."

            ORG_ID=$(awk 'BEGIN { FS = "\"" } !/^[ \t]*[{}]/ { print $(NF - 1); exit }' modal-login/temp-data/userData.json)
            echo "ORG_ID set to: $ORG_ID"
            
            # userApiKey.json이 존재하면 API 키가 이미 활성화되었다고 가정
            if [ -f "modal-login/temp-data/userApiKey.json" ]; then
                echo "userApiKey.json found. Assuming API key is already activated."
            else
                # API 키 활성화 확인 시도 (최대 30초)
                echo "Checking API key activation status..."
                ATTEMPTS=0
                MAX_ATTEMPTS=6  # 최대 6번(30초) 시도
                
                while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
                    STATUS=$(curl -s -m 5 "http://localhost:3000/api/get-api-key-status?orgId=$ORG_ID")
                    if [[ "$STATUS" == "activated" ]]; then
                        echo "API key is activated! Proceeding..."
                        break
                    else
                        echo "Waiting for API key to be activated... (attempt $((ATTEMPTS+1))/$MAX_ATTEMPTS)"
                        ATTEMPTS=$((ATTEMPTS+1))
                        sleep 5
                    fi
                done
            else
                echo "API key file found, assuming it's already activated. Proceeding..."
            fi

            # Save the ORG_ID, USER_DATA_JSON and USER_API_KEY_JSON to .env file for future use
            if [ ! -f "$ROOT/.env" ]; then
                touch "$ROOT/.env"
            fi
            
            # Save ORG_ID
            if ! grep -q "ORG_ID=" "$ROOT/.env"; then
                echo "ORG_ID=$ORG_ID" >> "$ROOT/.env"
            else
                sed -i "s/ORG_ID=.*/ORG_ID=$ORG_ID/" "$ROOT/.env"
            fi
            
            # Save USER_DATA_JSON
            USER_DATA_CONTENT=$(cat modal-login/temp-data/userData.json | tr -d '\n' | sed 's/"/\\"/g')
            if ! grep -q "USER_DATA_JSON=" "$ROOT/.env"; then
                echo "USER_DATA_JSON=\"$USER_DATA_CONTENT\"" >> "$ROOT/.env"
            else
                # Use a different delimiter for sed because our content might contain slashes
                sed -i "s|USER_DATA_JSON=.*|USER_DATA_JSON=\"$USER_DATA_CONTENT\"|" "$ROOT/.env"
            fi
            
            # Save USER_API_KEY_JSON
            USER_API_KEY_CONTENT=$(cat modal-login/temp-data/userApiKey.json | tr -d '\n' | sed 's/"/\\"/g')
            if ! grep -q "USER_API_KEY_JSON=" "$ROOT/.env"; then
                echo "USER_API_KEY_JSON=\"$USER_API_KEY_CONTENT\"" >> "$ROOT/.env"
            else
                # Use a different delimiter for sed because our content might contain slashes
                sed -i "s|USER_API_KEY_JSON=.*|USER_API_KEY_JSON=\"$USER_API_KEY_CONTENT\"|" "$ROOT/.env"
            fi

            # Function to clean up the server process
            cleanup() {
                echo "Shutting down server..."
                kill $SERVER_PID
                exit 0
            }

            # Set up trap to catch Ctrl+C and call cleanup
            trap cleanup INT
        else
            # Use the userData from .env
            echo "Using userData and userApiKey from .env file..."
            # Extract ORG_ID from USER_DATA_JSON
            # This assumes USER_DATA_JSON is formatted correctly
            ORG_ID=$(echo "$USER_DATA_JSON" | awk -F'"orgId":' '{print $2}' | awk -F'"' '{print $2}')
            echo "ORG_ID set to: $ORG_ID"
            
            # Create temporary files with the JSON content to be used by the application
            mkdir -p modal-login/temp-data
            echo "$USER_DATA_JSON" > modal-login/temp-data/userData.json
            echo "$USER_API_KEY_JSON" > modal-login/temp-data/userApiKey.json
        fi
    fi
else
    echo "Using ORG_ID, userData and userApiKey from .env file: $ORG_ID"
    CONNECT_TO_TESTNET=True
    
    # Ensure the temp-data directory exists and create the necessary JSON files
    mkdir -p modal-login/temp-data
    echo "$USER_DATA_JSON" > modal-login/temp-data/userData.json
    echo "$USER_API_KEY_JSON" > modal-login/temp-data/userApiKey.json
fi

#lets go!
echo "Getting requirements..."
pip install -r "$ROOT"/requirements-hivemind.txt > /dev/null
pip install -r "$ROOT"/requirements.txt > /dev/null

if ! which nvidia-smi; then
   #You don't have a NVIDIA GPU
   CONFIG_PATH="$ROOT/hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml"
elif [ -n "$CPU_ONLY" ]; then
   # ... or we don't want to use it
   CONFIG_PATH="$ROOT/hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml"
else
   #NVIDIA GPU found
   pip install -r "$ROOT"/requirements_gpu.txt > /dev/null
   CONFIG_PATH="$ROOT/hivemind_exp/configs/gpu/grpo-qwen-2.5-0.5b-deepseek-r1.yaml"
fi

echo ">> Done!"
echo ""
echo ""

if [ -n "${HF_TOKEN}" ]; then # Check if HF_TOKEN is already set from .env and use if so
   HUGGINGFACE_ACCESS_TOKEN=${HF_TOKEN}
   echo "Using Hugging Face token from .env file."
else
   read -p "Would you like to push models you train in the RL swarm to the Hugging Face Hub? [y/N] " yn
   yn=${yn:-N}  # Default to "N" if the user presses Enter
   case $yn in
      [Yy]* ) read -p "Enter your Hugging Face access token: " HUGGINGFACE_ACCESS_TOKEN;;
      [Nn]* ) HUGGINGFACE_ACCESS_TOKEN="None";;
      * ) echo ">>> No answer was given, so NO models will be pushed to Hugging Face Hub" && HUGGINGFACE_ACCESS_TOKEN="None";;
   esac
   
   # Save the HF_TOKEN to .env file for future use if provided
   if [ "$HUGGINGFACE_ACCESS_TOKEN" != "None" ]; then
       if [ ! -f "$ROOT/.env" ]; then
           touch "$ROOT/.env"
       fi
       if ! grep -q "HF_TOKEN=" "$ROOT/.env"; then
           echo "HF_TOKEN=$HUGGINGFACE_ACCESS_TOKEN" >> "$ROOT/.env"
       else
           sed -i "s/HF_TOKEN=.*/HF_TOKEN=$HUGGINGFACE_ACCESS_TOKEN/" "$ROOT/.env"
       fi
   fi
fi

echo ""
echo ""
echo "Good luck in the swarm!"

if [ -n "$ORG_ID" ]; then
    python -m hivemind_exp.gsm8k.train_single_gpu \
        --hf_token "$HUGGINGFACE_ACCESS_TOKEN" \
        --identity_path "$IDENTITY_PATH" \
        --modal_org_id "$ORG_ID" \
        --config "$CONFIG_PATH"
else
    python -m hivemind_exp.gsm8k.train_single_gpu \
        --hf_token "$HUGGINGFACE_ACCESS_TOKEN" \
        --identity_path "$IDENTITY_PATH" \
        --public_maddr "$PUB_MULTI_ADDRS" \
        --initial_peers "$PEER_MULTI_ADDRS"\
        --host_maddr "$HOST_MULTI_ADDRS" \
        --config "$CONFIG_PATH"
fi

wait  # Keep script running until Ctrl+C
