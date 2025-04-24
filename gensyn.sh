#!/bin/bash

# RL Swarm 노드 원클릭 설치 스크립트
# 작성일: 2025-04-01

# 색상 설정
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================================${NC}"
echo -e "${GREEN}           RL SWARM 노드 설치 스크립트               ${NC}"
echo -e "${BLUE}=======================================================${NC}"

# 설치 옵션 설정 (기본값: 모두 설치)
INSTALL_SYSTEM_PACKAGES=true
INSTALL_UTILITIES=true
INSTALL_DOCKER=true
INSTALL_PYTHON=true
INSTALL_NODEJS=true
INSTALL_YARN=true
INSTALL_RL_SWARM=true
INSTALL_DASHBOARD=true

# 인자 파싱
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-system) INSTALL_SYSTEM_PACKAGES=false ;;
        --skip-utils) INSTALL_UTILITIES=false ;;
        --skip-docker) INSTALL_DOCKER=false ;;
        --skip-python) INSTALL_PYTHON=false ;;
        --skip-nodejs) INSTALL_NODEJS=false ;;
        --skip-yarn) INSTALL_YARN=false ;;
        --skip-rl-swarm) INSTALL_RL_SWARM=false ;;
        --skip-dashboard) INSTALL_DASHBOARD=false ;;
        --help) 
            echo "사용법: $0 [옵션]"
            echo "옵션:"
            echo "  --skip-system     : 시스템 패키지 업데이트 건너뛰기"
            echo "  --skip-utils      : 유틸리티 설치 건너뛰기"
            echo "  --skip-docker     : Docker 설치 건너뛰기"
            echo "  --skip-python     : Python 설치 건너뛰기"
            echo "  --skip-nodejs     : Node.js 설치 건너뛰기"
            echo "  --skip-yarn       : Yarn 설치 건너뛰기"
            echo "  --skip-rl-swarm   : RL Swarm 설치 건너뛰기"
            echo "  --skip-dashboard  : 대시보드 설치 건너뛰기"
            exit 0
            ;;
        *) echo "알 수 없는 옵션: $1"; exit 1 ;;
    esac
    shift
done

# 대화형 모드에서 설치 옵션 선택
if [ -t 0 ]; then  # 터미널에서 실행 중인지 확인
    echo -e "\n${YELLOW}설치 옵션을 선택하세요 (y/n):${NC}"
    
    read -p "시스템 패키지 업데이트를 진행할까요? [Y/n] " response
    [[ "$response" =~ ^[Nn] ]] && INSTALL_SYSTEM_PACKAGES=false
    
    read -p "유틸리티를 설치할까요? [Y/n] " response
    [[ "$response" =~ ^[Nn] ]] && INSTALL_UTILITIES=false
    
    read -p "Docker를 설치할까요? [Y/n] " response
    [[ "$response" =~ ^[Nn] ]] && INSTALL_DOCKER=false
    
    read -p "Python을 설치할까요? [Y/n] " response
    [[ "$response" =~ ^[Nn] ]] && INSTALL_PYTHON=false
    
    read -p "Node.js를 설치할까요? [Y/n] " response
    [[ "$response" =~ ^[Nn] ]] && INSTALL_NODEJS=false
    
    read -p "Yarn을 설치할까요? [Y/n] " response
    [[ "$response" =~ ^[Nn] ]] && INSTALL_YARN=false
    
    read -p "RL Swarm을 설치할까요? [Y/n] " response
    [[ "$response" =~ ^[Nn] ]] && INSTALL_RL_SWARM=false
    
    read -p "대시보드를 설치할까요? [Y/n] " response
    [[ "$response" =~ ^[Nn] ]] && INSTALL_DASHBOARD=false
    
    echo ""
fi

# 함수: 진행 상태 출력
print_progress() {
    echo -e "${YELLOW}[$(date +%T)]${NC} $1"
}

# 함수: 오류 출력
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 함수: 성공 출력
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 함수: 명령 실행 및 오류 처리
run_command() {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        print_error "명령 실행 중 오류 발생: $*"
        echo -e "${YELLOW}계속 진행할까요? (y/n)${NC}"
        read -r answer
        if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
            exit $status
        fi
    fi
    return $status
}

# 함수: 시스템 패키지 업데이트
update_system() {
    if [ "$INSTALL_SYSTEM_PACKAGES" = true ]; then
        print_progress "1. 시스템 패키지 업데이트 중..."
        run_command sudo apt-get update
        run_command sudo apt-get upgrade -y
        print_success "시스템 패키지 업데이트 완료"
    else
        print_progress "시스템 패키지 업데이트 건너뜀"
    fi
}

# 함수: 일반 유틸리티 및 도구 설치
install_utilities() {
    if [ "$INSTALL_UTILITIES" = true ]; then
        print_progress "2. 일반 유틸리티 및 도구 설치 중..."
        run_command sudo apt-get install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev
        print_success "일반 유틸리티 및 도구 설치 완료"
    else
        print_progress "일반 유틸리티 및 도구 설치 건너뜀"
    fi
}

# 함수: Docker 설치
install_docker() {
    if [ "$INSTALL_DOCKER" = true ]; then
        print_progress "3. Docker 설치 중..."
        
        # 기존 Docker 설치 제거
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
            run_command sudo apt-get remove $pkg -y 2>/dev/null || true
        done
        
        # Docker 저장소 추가
        run_command sudo apt-get update
        run_command sudo apt-get install -y ca-certificates curl gnupg
        run_command sudo install -m 0755 -d /etc/apt/keyrings
        
        # GPG 키 가져오기 - 오류 처리 추가
        if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
            run_command sudo chmod a+r /etc/apt/keyrings/docker.gpg
            
            # 저장소 추가 - EOF로 변경하여 변수 확장 문제 방지
            codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
            architecture=$(dpkg --print-architecture)
            
            echo "deb [arch=${architecture} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Docker 설치
            if run_command sudo apt-get update; then
                run_command sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                
                # Docker 테스트 - 실패해도 계속 진행
                sudo docker run hello-world || print_error "Docker 테스트 실패, 하지만 계속 진행합니다."
                
                # 사용자를 Docker 그룹에 추가
                run_command sudo usermod -aG docker $USER
                
                print_success "Docker 설치 완료 (sudo 없이 Docker를 실행하려면 재로그인이 필요합니다)"
            else
                print_error "Docker 저장소 업데이트 실패, Docker 설치를 건너뜁니다."
            fi
        else
            print_error "Docker GPG 키 가져오기 실패, Docker 설치를 건너뜁니다."
        fi
    else
        print_progress "Docker 설치 건너뜀"
    fi
}

# 함수: Python 설치
install_python() {
    if [ "$INSTALL_PYTHON" = true ]; then
        print_progress "4. Python 설치 중..."
        run_command sudo apt-get install -y python3 python3-pip python3.10-venv
        print_success "Python 설치 완료"
    else
        print_progress "Python 설치 건너뜀"
    fi
}

# 함수: Node.js 설치
install_nodejs() {
    if [ "$INSTALL_NODEJS" = true ]; then
        print_progress "5. Node.js 설치 중..."
        # LTS 버전(현재 20.x) 사용
        if curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -; then
            run_command sudo apt-get install -y nodejs
            node_version=$(node -v 2>/dev/null || echo "확인 불가")
            print_success "Node.js 설치 완료: ${node_version}"
        else
            print_error "Node.js 저장소 설정 실패, Node.js 설치를 건너뜁니다."
        fi
    else
        print_progress "Node.js 설치 건너뜀"
    fi
}

# 함수: Yarn 설치
install_yarn() {
    if [ "$INSTALL_YARN" = true ]; then
        print_progress "6. Yarn 설치 중..."
        if command -v npm &> /dev/null; then
            run_command sudo npm install -g yarn
            
            if ! curl -o- -L https://yarnpkg.com/install.sh | bash; then
                print_error "Yarn 스크립트 설치 실패, 하지만 npm으로 이미 설치되었습니다."
            fi
            
            # PATH 추가 - 이미 있는지 확인 후 추가
            if ! grep -q "export PATH=\"\$HOME/.yarn/bin:\$HOME/.config/yarn/global/node_modules/.bin:\$PATH\"" ~/.bashrc; then
                echo 'export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"' >> ~/.bashrc
            fi
            export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
            
            yarn_version=$(yarn -v 2>/dev/null || echo "확인 불가")
            print_success "Yarn 설치 완료: ${yarn_version}"
        else
            print_error "npm을 찾을 수 없어 Yarn 설치를 건너뜁니다."
        fi
    else
        print_progress "Yarn 설치 건너뜀"
    fi
}

# 함수: HuggingFace 액세스 토큰 안내
huggingface_token_guide() {
    print_progress "HuggingFace 액세스 토큰 설정"
    echo -e "${YELLOW}중요:${NC} RL Swarm을 실행하려면 HuggingFace 액세스 토큰이 필요합니다."
    echo -e "1. ${BLUE}https://huggingface.co${NC}에 방문하여 계정을 생성하거나, 로그인하세요."
    echo -e "2. ${BLUE}https://huggingface.co/settings/tokens${NC}에서 'Write' 권한이 있는 새 토큰을 생성하세요."
    echo -e "3. 해당 토큰을 안전한 곳에 저장해두세요. 나중에 RL Swarm을 실행할 때 필요합니다.\n"
    
    read -p "HuggingFace 토큰을 받으셨나요? (y/n): " huggingface_ready
    if [[ "$huggingface_ready" != "y" ]]; then
        echo -e "${YELLOW}나중에 토큰을 준비한 후 RL Swarm을 실행해주세요.${NC}"
    fi
}

# 함수: RL Swarm 설치
install_rl_swarm() {
    if [ "$INSTALL_RL_SWARM" = true ]; then
        print_progress "7. RL Swarm 설치 중..."
        cd $HOME
        
        # 이미 존재하는 경우 건너뛰기 옵션 제공
        if [ -d "$HOME/rl-swarm" ]; then
            read -p "RL Swarm 디렉토리가 이미 존재합니다. 다시 클론하시겠습니까? (y/n): " reclone
            if [[ "$reclone" == "y" ]]; then
                # 백업 .pem 파일 (있는 경우)
                if [ -f "$HOME/rl-swarm/swarm.pem" ]; then
                    cp "$HOME/rl-swarm/swarm.pem" "$HOME/swarm.pem.backup"
                    echo "기존 swarm.pem 파일이 백업되었습니다."
                fi
                rm -rf "$HOME/rl-swarm"
                run_command git clone https://github.com/gensyn-ai/rl-swarm/
                # 백업된 .pem 파일 복원 (있는 경우)
                if [ -f "$HOME/swarm.pem.backup" ]; then
                    cp "$HOME/swarm.pem.backup" "$HOME/rl-swarm/swarm.pem"
                    echo "swarm.pem 파일이 복원되었습니다."
                fi
            fi
        else
            run_command git clone https://github.com/gensyn-ai/rl-swarm/
        fi
        
        cd rl-swarm

        # 가상 환경 설정
        if [ ! -d ".venv" ]; then
            run_command python3 -m venv .venv
        fi
        source .venv/bin/activate

        print_success "RL Swarm 설치 완료"
    else
        print_progress "RL Swarm 설치 건너뜀"
    fi
}

# 함수: RL Swarm 실행
run_rl_swarm() {
    if [ "$INSTALL_RL_SWARM" = true ]; then
        print_progress "8. RL Swarm 실행 준비 중..."
        cd $HOME/rl-swarm
        
        # run_swarm.sh 생성 - 로깅 활성화 추가
        cat > run_swarm.sh << 'EOF'
#!/bin/bash
cd $HOME/rl-swarm
source .venv/bin/activate
./run_rl_swarm.sh
EOF
        chmod +x run_swarm.sh
        
        # Screen 세션에서 실행 - 로깅 활성화
        cat > start_swarm.sh << 'EOF'
#!/bin/bash
# Screen 로깅 활성화
cd $HOME/rl-swarm
screen -L -Logfile screenlog.0 -S swarm -dm bash -c "./run_swarm.sh"
echo "RL Swarm이 백그라운드에서 실행 중입니다. 다음 명령으로 확인할 수 있습니다: screen -r swarm"
EOF
        chmod +x start_swarm.sh
        
        # Screen 세션 종료 스크립트
        cat > stop_swarm.sh << 'EOF'
#!/bin/bash
screen -XS swarm quit
echo "RL Swarm이 중지되었습니다."
EOF
        chmod +x stop_swarm.sh
        
        print_success "RL Swarm 실행 스크립트 준비 완료"
    else
        print_progress "RL Swarm 실행 준비 건너뜀"
    fi
}

# 함수: 대시보드 UI 설치
install_dashboard() {
    if [ "$INSTALL_DASHBOARD" = true ] && [ "$INSTALL_RL_SWARM" = true ]; then
        print_progress "9. Swarm 대시보드 UI 설치 중..."
        
        # Docker가 설치되었는지 확인
        if ! command -v docker &> /dev/null; then
            print_error "Docker가 설치되지 않았습니다. 대시보드 UI 설치를 건너뜁니다."
            return 1
        fi
        
        cd $HOME/rl-swarm
        
        # Docker Compose 명령 실행
        if ! run_command docker compose up -d --build; then
            print_error "Docker Compose 실행 실패, 다시 시도하려면 나중에 '$HOME/rl-swarm'에서 'docker compose up -d --build'를 실행하세요."
            return 1
        fi
        
        # 서버 IP 확인
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "확인 불가")
        
        print_success "Swarm 대시보드 UI 설치 완료"
        echo -e "${GREEN}로컬 액세스:${NC} http://0.0.0.0:8080"
        echo -e "${GREEN}원격 액세스:${NC} http://$SERVER_IP:8080"
    else
        print_progress "Swarm 대시보드 UI 설치 건너뜀"
    fi
}

# 함수: 관리 메뉴 생성
create_management_menu() {
    print_progress "10. 노드 관리 메뉴 생성 중..."
    cd $HOME
    cat > manage_rl_swarm.sh << 'EOF'
#!/bin/bash

# 색상 설정
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

while true; do
    clear
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "${GREEN}           RL SWARM 노드 관리 메뉴                  ${NC}"
    echo -e "${BLUE}=======================================================${NC}"
    
    # 노드 실행 상태 확인
    if screen -list | grep -q "swarm"; then
        echo -e "${GREEN}[상태] RL Swarm 노드가 실행 중입니다${NC}"
        
        # 노드 이름 찾기 시도
        SCREENLOG="$HOME/rl-swarm/screenlog.0"
        if [ -f "$SCREENLOG" ]; then
            NODE_NAME=$(grep -a "Hello" "$SCREENLOG" 2>/dev/null | tail -1 | grep -o "Hello [a-z ]*" | sed 's/Hello //' || echo "아직 설정되지 않음")
            NODE_ID=$(grep -a "Node ID" "$SCREENLOG" 2>/dev/null | tail -1 | awk '{print $NF}' || echo "확인 불가")
            echo -e "${YELLOW}[노드 이름] ${NODE_NAME}${NC}"
            echo -e "${YELLOW}[노드 ID] ${NODE_ID}${NC}"
        else
            echo -e "${YELLOW}[노드 이름] 로그 파일을 찾을 수 없습니다${NC}"
        fi
    else
        echo -e "${RED}[상태] RL Swarm 노드가 실행 중이 아닙니다${NC}"
    fi
    
    echo -e "\n${YELLOW}메뉴 선택:${NC}"
    echo "1) RL Swarm 노드 시작"
    echo "2) RL Swarm 노드 중지"
    echo "3) RL Swarm 로그 보기"
    echo "4) 노드 백업 (.pem 파일 확인)"
    echo "5) 대시보드 UI 실행/재시작"
    echo "6) 시스템 정보 보기"
    echo "7) 로그 파일 정리"
    echo "8) 노드 업데이트"
    echo "9) 종료"
    
    read -p "옵션 선택 (1-9): " choice
    
    case $choice in
        1)
            if screen -list | grep -q "swarm"; then
                echo -e "${YELLOW}RL Swarm 노드가 이미 실행 중입니다.${NC}"
            else
                cd $HOME/rl-swarm
                ./start_swarm.sh
                echo -e "${GREEN}RL Swarm 노드가 시작되었습니다.${NC}"
                echo -e "${YELLOW}로그인 페이지 접속 방법:${NC}"
                echo -e "1. 로컬 PC: http://localhost:3000/"
                echo -e "2. VPS 사용자: 로컬 PC에서 다음 명령 실행 후 http://localhost:3000/ 접속"
                echo -e "   ssh -L 3000:localhost:3000 사용자명@서버IP -p SSH포트"
            fi
            ;;
        2)
            if screen -list | grep -q "swarm"; then
                cd $HOME/rl-swarm
                ./stop_swarm.sh
                echo -e "${YELLOW}RL Swarm 노드가 중지되었습니다.${NC}"
            else
                echo -e "${RED}실행 중인 RL Swarm 노드가 없습니다.${NC}"
            fi
            ;;
        3)
            if screen -list | grep -q "swarm"; then
                echo -e "${YELLOW}로그를 보려면 CTRL+A+D를 눌러 나갈 수 있습니다.${NC}"
                read -p "계속하려면 Enter 키를 누르세요..." -r
                screen -r swarm
            else
                echo -e "${RED}실행 중인 RL Swarm 노드가 없습니다.${NC}"
            fi
            ;;
        4)
            echo -e "${YELLOW}노드 백업 정보:${NC}"
            PEM_FILE="$HOME/rl-swarm/swarm.pem"
            if [ -f "$PEM_FILE" ]; then
                # PEM 파일 권한 확인 및 설정
                CURRENT_PERMS=$(stat -c "%a" "$PEM_FILE")
                if [ "$CURRENT_PERMS" != "600" ]; then
                    chmod 600 "$PEM_FILE"
                    echo -e "${YELLOW}PEM 파일 권한을 안전하게 설정했습니다 (600).${NC}"
                fi
                
                echo -e "${GREEN}PEM 파일 위치: $PEM_FILE${NC}"
                echo -e "${YELLOW}이 파일을 안전하게 백업하세요.${NC}"
                
                # 백업 옵션
                echo -e "\n백업 옵션:"
                echo "1) PEM 파일 내용 보기"
                echo "2) PEM 파일 백업하기"
                echo "3) 돌아가기"
                
                read -p "옵션 선택 (1-3): " backup_choice
                case $backup_choice in
                    1) cat "$PEM_FILE" ;;
                    2)
                        BACKUP_DIR="$HOME/rl-swarm-backup"
                        mkdir -p "$BACKUP_DIR"
                        BACKUP_FILE="$BACKUP_DIR/swarm-$(date +%Y%m%d-%H%M%S).pem"
                        cp "$PEM_FILE" "$BACKUP_FILE"
                        chmod 600 "$BACKUP_FILE"
                        echo -e "${GREEN}PEM 파일이 백업되었습니다: $BACKUP_FILE${NC}"
                        ;;
                    *) echo "돌아갑니다." ;;
                esac
            else
                echo -e "${RED}PEM 파일을 찾을 수 없습니다. 노드가 아직 실행되지 않았거나 초기화되지 않았을 수 있습니다.${NC}"
            fi
            ;;
        5)
            if command -v docker &> /dev/null; then
                cd $HOME/rl-swarm
                docker compose down
                docker compose up -d --build
                SERVER_IP=$(curl -s ifconfig.me)
                echo -e "${GREEN}Swarm 대시보드 UI가 재시작되었습니다.${NC}"
                echo -e "${GREEN}로컬 액세스:${NC} http://0.0.0.0:8080"
                echo -e "${GREEN}원격 액세스:${NC} http://$SERVER_IP:8080"
            else
                echo -e "${RED}Docker가 설치되지 않았습니다. 대시보드를 실행할 수 없습니다.${NC}"
            fi
            ;;
        6)
            echo -e "\n${YELLOW}시스템 정보:${NC}"
            echo -e "${BLUE}CPU:${NC} $(lscpu | grep 'Model name' | cut -f 2 -d ":" | awk '{$1=$1}1')"
            echo -e "${BLUE}메모리:${NC} $(free -h | grep 'Mem' | awk '{print $2}')"
            echo -e "${BLUE}디스크:${NC} $(df -h / | awk 'NR==2 {print $2}')"
            echo -e "${BLUE}운영체제:${NC} $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2)"
            echo -e "${BLUE}커널:${NC} $(uname -r)"
            
            # GPU 정보 확인 (nvidia-smi가 있는 경우)
            if command -v nvidia-smi &> /dev/null; then
                echo -e "\n${YELLOW}GPU 정보:${NC}"
                nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader
            fi
            
            # 설치된 경우에만 표시
            if command -v docker &> /dev/null; then
                echo -e "${BLUE}Docker:${NC} $(docker --version)"
            else
                echo -e "${BLUE}Docker:${NC} 설치되지 않음"
            fi
            
            if command -v node &> /dev/null; then
                echo -e "${BLUE}Node.js:${NC} $(node -v)"
            else
                echo -e "${BLUE}Node.js:${NC} 설치되지 않음"
            fi
            
            if command -v python3 &> /dev/null; then
                echo -e "${BLUE}Python:${NC} $(python3 --version)"
            else
                echo -e "${BLUE}Python:${NC} 설치되지 않음"
            fi
            ;;
        7)
            SCREENLOG="$HOME/rl-swarm/screenlog.0"
            if [ -f "$SCREENLOG" ]; then
                SIZE=$(du -h "$SCREENLOG" | cut -f1)
                echo -e "${YELLOW}현재 로그 파일 크기: $SIZE${NC}"
                echo -e "1) 로그 파일 백업 및 정리"
                echo -e "2) 로그 파일 삭제"
                echo -e "3) 돌아가기"
                
                read -p "옵션 선택 (1-3): " log_choice
                case $log_choice in
                    1)
                        BACKUP_DIR="$HOME/rl-swarm-logs"
                        mkdir -p "$BACKUP_DIR"
                        BACKUP_FILE="$BACKUP_DIR/screenlog-$(date +%Y%m%d-%H%M%S).txt"
                        cp "$SCREENLOG" "$BACKUP_FILE"
                        truncate -s 0 "$SCREENLOG"
                        echo -e "${GREEN}로그가 백업되었습니다: $BACKUP_FILE${NC}"
                        echo -e "${GREEN}로그 파일이 정리되었습니다.${NC}"
                        ;;
                    2)
                        truncate -s 0 "$SCREENLOG"
                        echo -e "${GREEN}로그 파일이 삭제되었습니다.${NC}"
                        ;;
                    *) echo "돌아갑니다." ;;
                esac
            else
                echo -e "${RED}로그 파일을 찾을 수 없습니다.${NC}"
            fi
            ;;
        8)
            echo -e "${YELLOW}노드 업데이트 옵션:${NC}"
            echo "1) 기본 업데이트 (git pull)"
            echo "2) 로컬 변경사항 초기화 후 업데이트"
            echo "3) 완전 새로 설치 (swarm.pem 백업 유지)"
            echo "4) 돌아가기"
            
            read -p "업데이트 방법 선택 (1-4): " update_choice
            case $update_choice in
                1)
                    cd $HOME/rl-swarm
                    git pull
                    echo -e "${GREEN}RL Swarm이 업데이트되었습니다.${NC}"
                    ;;
                2)
                    cd $HOME/rl-swarm
                    git reset --hard
                    git pull
                    echo -e "${GREEN}RL Swarm이 초기화 후 업데이트되었습니다.${NC}"
                    ;;
                3)
                    cd $HOME/rl-swarm
                    if [ -f "./swarm.pem" ]; then
                        cp ./swarm.pem ~/swarm.pem.backup
                        echo -e "${YELLOW}swarm.pem 파일이 백업되었습니다.${NC}"
                    fi
                    cd ..
                    rm -rf rl-swarm
                    git clone https://github.com/gensyn-ai/rl-swarm
                    cd rl-swarm
                    if [ -f "$HOME/swarm.pem.backup" ]; then
                        cp $HOME/swarm.pem.backup ./swarm.pem
                        echo -e "${GREEN}swarm.pem 파일이 복원되었습니다.${NC}"
                    fi
                    echo -e "${GREEN}RL Swarm이 완전히 새로 설치되었습니다.${NC}"
                    ;;
                *) echo "돌아갑니다." ;;
            esac
            ;;
        9)
            echo -e "${GREEN}RL Swarm 노드 관리 메뉴를 종료합니다.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}잘못된 옵션입니다. 다시 시도하세요.${NC}"
            ;;
    esac
    
    read -p "계속하려면 Enter 키를 누르세요..." -r
done
EOF
    chmod +x manage_rl_swarm.sh
    print_success "노드 관리 메뉴 생성 완료"
}

# 함수: 설치 완료 메시지
installation_complete() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "확인 불가")
    
    echo -e "\n${BLUE}=======================================================${NC}"
    echo -e "${GREEN}           RL SWARM 노드 설치 완료!                  ${NC}"
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "\n${YELLOW}다음 단계:${NC}"
    echo -e "1. 관리 메뉴를 실행하세요: ${GREEN}$HOME/manage_rl_swarm.sh${NC}"
    echo -e "2. 메뉴에서 '1) RL Swarm 노드 시작'을 선택하여 노드를 실행하세요."
    echo -e "3. 로그인 페이지 접속 방법:"
    echo -e "   - 로컬 PC: ${GREEN}http://localhost:3000/${NC}"
    echo -e "   - VPS 사용자: 로컬 PC에서 다음 명령 실행 후 ${GREEN}http://localhost:3000/${NC} 접속"
    echo -e "     ${BLUE}ssh -L 3000:localhost:3000 사용자명@$SERVER_IP -p SSH포트${NC}"
    echo -e "4. 대시보드 UI에 액세스하려면 다음 주소를 사용하세요:"
    echo -e "   ${GREEN}로컬 액세스:${NC} http://0.0.0.0:8080"
    echo -e "   ${GREEN}원격 액세스:${NC} http://$SERVER_IP:8080"
    echo -e "\n${YELLOW}중요:${NC} HuggingFace 액세스 토큰을 준비해 주세요. RL Swarm 실행 시 필요합니다."
    echo -e "   ${BLUE}https://huggingface.co/settings/tokens${NC}에서 'Write' 권한이 있는 토큰을 생성하고 보관하세요."
    echo -e "\n${YELLOW}노드 상태 확인:${NC}"
    echo -e "   텔레그램 봇: ${BLUE}https://t.me/gensyntrackbot${NC} - /check 명령어로 노드 ID 확인"
    echo -e "   공식 대시보드: ${BLUE}https://dashboard.gensyn.ai/${NC}"
}

# 메인 설치 프로세스 실행
update_system
install_utilities
install_docker
install_python
install_nodejs
install_yarn
huggingface_token_guide
install_rl_swarm
run_rl_swarm
install_dashboard
create_management_menu
installation_complete

echo -e "\n${GREEN}설치가 완료되었습니다!${NC}"
