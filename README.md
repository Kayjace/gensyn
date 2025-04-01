# RL Swarm (Testnet) 노드 실행 가이드

RL Swarm은 GensynAI에서 개발한 완전 오픈소스 프레임워크로, 인터넷을 통해 강화학습(RL) 훈련 스웜을 구축하기 위한 도구입니다. 이 가이드는 RL Swarm 노드 설정 및 스웜 활동을 모니터링하기 위한 웹 UI 대시보드 설치 방법을 안내합니다.

## 하드웨어 요구사항

- **CPU**: 최소 16GB RAM (더 큰 모델이나 데이터셋의 경우 더 많은 RAM 권장)
- **또는**
- **GPU(선택사항)**: 성능 향상을 위한 지원되는 CUDA 장치:
  - RTX 3090
  - RTX 4090
  - A100
  - H100

**참고**: CPU 전용 모드로 GPU 없이도 노드를 실행할 수 있습니다.

## 1) 의존성 설치

### 1. 시스템 패키지 업데이트

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

### 2. 일반 유틸리티 및 도구 설치

```bash
sudo apt install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
```

### 3. Docker 설치

```bash
# 기존 Docker 설치 제거
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Docker 저장소 추가
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 설치
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker 테스트
sudo docker run hello-world
```

**팁**: sudo 없이 Docker를 실행하려면 사용자를 Docker 그룹에 추가하세요:
```bash
sudo usermod -aG docker $USER
```

### 4. Python 설치

```bash
sudo apt-get install python3 python3-pip
sudo apt install python3.10-venv
```

### 5. Node 설치

```bash
sudo apt-get update
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v
sudo npm install -g yarn
yarn -v
```

### 6. Yarn 설치

```bash
curl -o- -L https://yarnpkg.com/install.sh | sh
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
source ~/.bashrc
```

## 2) HuggingFace 액세스 토큰 얻기

1. HuggingFace에 계정 생성
2. 여기에서 쓰기 권한이 있는 액세스 토큰을 생성하고 저장

## 3) 저장소 클론

```bash
git clone https://github.com/gensyn-ai/rl-swarm/
cd rl-swarm
```

## 4) 스웜 실행

백그라운드에서 실행하기 위한 스크린 열기:

```bash
screen -S swarm
```

스웜 설치:

```bash
python3 -m venv .venv
source .venv/bin/activate
./run_rl_swarm.sh
```

Y를 누르세요.

## 5) 로그인

1. 로그에서 "Waiting for userData.json to be created..." 메시지가 표시되어야 합니다.

2. 브라우저에서 로그인 페이지 열기:
   - 로컬 PC: http://localhost:3000/
   - VPS: http://ServerIP:3000/

3. VPS를 통해 로그인할 수 없는 경우 포트 포워딩:
   
   Windows 시작 메뉴에서 PowerShell을 검색하고 로컬 PC에서 터미널을 엽니다.
   아래 명령을 입력하고 Server_IP를 VPS IP로, SSH_PORT를 VPS 포트(예: 22)로 바꿉니다.
   
   ```bash
   ssh -L 3000:localhost:3000 root@Server_IP -p SSH_PORT
   ```
   
   VPS 비밀번호를 입력하라는 메시지가 표시되면 입력하여 VPS에 연결하고 터널링합니다.
   이제 브라우저에서 http://localhost:3000/을 열고 로그인합니다.

4. 원하는 방법으로 로그인하세요.

5. 로그인 후 터미널에서 설치가 시작됩니다.

6. 모델을 huggingface에 푸시:
   메시지가 표시되면 생성한 HuggingFace 액세스 토큰을 입력하세요.

## 6) 백업

1. 노드 이름:
   노드가 실행되기 시작하면 "Hello" 단어 뒤에 이름을 찾으세요. (터미널에서 CTRL+SHIFT+F를 사용하여 "Hello"를 검색할 수 있습니다)

2. 노드 .pem 파일:
   swarm.pem 파일을 다음 디렉토리에 저장하세요: /root/rl-swarm/

**스크린 명령어**:
- 최소화: CTRL + A + D
- 복귀: screen -r swarm
- 중지 및 종료: screen -XS swarm quit

## 7) Swarm 대시보드 UI 실행 (선택사항)

```bash
cd $HOME
cd rl-swarm
docker compose up -d --build
```

브라우저에서 대시보드 열기:
- 로컬 PC: 0.0.0.0:8080
- VPS: ServerIP:8080
- 공식 대시보드: https://dashboard.gensyn.ai/

첫 번째 훈련이 완료된 후 대시보드에서 노드 이름을 검색할 수 있습니다.

---
Perplexity로부터의 답변: pplx.ai/share
