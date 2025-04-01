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

**참고**: CPU 전용 모드로 맥에서 gpu없이 노드 실행이 가능합니다.

**RL Swarm 노드 설치를 위해 해당 저장소의 gensyn.sh 스크립트를 사용할 수 있습니다. 이 스크립트는 시스템 패키지 업데이트부터 Docker, Python, Node.js, Yarn 등 모든 필요한 의존성을 설치합니다. 다음 명령어로 스크립트를 다운로드하고 실행할 수 있습니다:**

```bash
curl -O https://raw.githubusercontent.com/Kayjace/gensyn/main/gensyn.sh
chmod +x gensyn.sh
./gensyn.sh
```

스크립트를 실행하면 대화형 모드에서 각 구성 요소의 설치 여부를 선택할 수 있습니다. 필요한 구성 요소만 설치하려면 해당 프롬프트에서 'y'를 입력하고, 그렇지 않으면 'n'을 입력하면 됩니다.

## 설치 후에는 `$HOME/manage_rl_swarm.sh` 명령어로 관리 메뉴를 실행하여 노드를 시작하고 관리할 수 있습니다


## HuggingFace 액세스 토큰 얻기

1. HuggingFace(https://huggingface.co) 에 계정 생성 후 이메일 인증하기.
2. 여기에서 쓰기 권한이 있는 액세스 토큰을 생성하고 저장 (https://huggingface.co/settings/tokens 에서 permission이 write인 토큰 생성. 이거 잊어버리면 그냥 재생성하고 다시 넣으셔도 됩니다. 에어드랍 받는 계정이랑 관계 x)


## manage_rl_swarm.sh 말고 직접 실행하기
```bash
cd $home
cd rl-swarm
```
후

백그라운드에서 실행하기 위한 스크린 열기: (tmux를 쓰시거나 하면 생략 가능)

```bash
screen -S swarm
```

**실행커맨드**

```bash
python3 -m venv .venv
source .venv/bin/activate
./run_rl_swarm.sh
```

Y를 누르세요.

## 로그인

1. Y를 눌렀다면 로그에서 "Waiting for userData.json to be created..." 메시지가 표시되어야 합니다.

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

4. 원하는 방법으로 로그인하세요. (구글 계정 로그인 등 관계없음)

5. 로그인 후 터미널에서 설치가 시작됩니다.

6. 모델을 huggingface에 푸시할까요?
   메시지가 표시되면 Y를 누르고 이전에 생성한 HuggingFace 액세스 토큰을 입력하세요. (리프레쉬해서 넣어도 관계없음)

## 백업 관련

1. 노드 이름:
   노드가 실행되기 시작하면 "Hello" 단어 뒤에 이름을 찾으세요. INFO:hivemind_exp.runner.grpo_runner:🐱 Hello 🐈 [단어 단어 단어] 형태 나오고 🦮 [자신의 피어 id]
   INFO:hivemind_exp.runner.gensyn.testnet_grpo_runner:Registering self with peer ID 뒤에서도 peer id 확인 가능.
   [단어 단어 단어] 의 노드 이름으로 이후 대시보드에서 노드 이름 검색 가능.
   
3. 노드 .pem 파일:
   swarm.pem 파일을 다음 디렉토리에 저장하세요: /root/rl-swarm/

**스크린 명령어**:
- 최소화: CTRL + A + D
- 복귀: screen -r swarm
- 중지 및 종료: screen -XS swarm quit

## Swarm 대시보드 UI 실행 (선택사항) - 공식 대시보드도 있으므로 필수는 아닙니다.

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
