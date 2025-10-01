#!/data/data/com.termux/files/usr/bin/bash

# =========================================================
# Skrip Peluncuran Server XIPSER (ANTI-ERROR)
# Digunakan untuk menjalankan Server dan Ngrok secara paralel
# Gunakan perintah: ./start.sh
# =========================================================

MC_PORT=19132
SERVER_DIR="$HOME/mcbe_server"
ADMIN_LIST="$SERVER_DIR/permissions.json"

function check_permissions() {
    # Memeriksa dan memastikan file permissions.json ada
    if [ ! -f "$ADMIN_LIST" ]; then
        echo "Membuat file permissions.json default..."
        echo '[{"xuid": "", "permission": "member"}]' > "$ADMIN_LIST"
    fi
}

function add_admin() {
    PLAYER_NAME=$1
    if [ -z "$PLAYER_NAME" ]; then
        echo "🚫 ERROR: Nama pemain tidak boleh kosong. Contoh: ./start.sh add_admin Budi_Ganteng"
        return
    fi
    
    echo "========================================================="
    echo "      ADMIN MODE: Menambahkan Player Admin (OP)"
    echo "========================================================="
    echo "Silakan masuk ke konsol server (Jendela 1) dan ketik:"
    echo "op \"$PLAYER_NAME\""
    echo "Setelah itu, ketik 'stop' atau 'exit' untuk mematikan server admin mode."
    echo "========================================================="
    
    # Jalankan hanya Bedrock Server sementara untuk perintah op
    tmux new-session -s temp_admin
    tmux send-keys -t temp_admin "cd $SERVER_DIR" C-m
    tmux send-keys -t temp_admin "LD_LIBRARY_PATH=. ./bedrock_server" C-m
    
    # Lampirkan dan instruksikan user
    tmux attach-session -t temp_admin
    
    echo "Proses Admin Selesai. Gunakan './start.sh' untuk menjalankan server normal."
}


function start_server() {
    echo "========================================================="
    echo "⚡ Memulai XIPSER Server dan Ngrok Tunnel (Port: $MC_PORT) ⚡"
    echo "========================================================="

    # Mematikan sesi tmux sebelumnya jika ada
    tmux kill-session -t mcbe_online 2>/dev/null

    # Membuat sesi tmux baru
    tmux new-session -d -s mcbe_online

    # Jendela 0: Ngrok Tunnel
    tmux send-keys -t mcbe_online:0 "$HOME/ngrok tcp $MC_PORT" C-m
    tmux rename-window -t mcbe_online:0 "Ngrok_IP_PORT (Jendela 0)"

    # Jendela 1: Minecraft Bedrock Server (Xipser)
    tmux new-window -t mcbe_online:1 -n "Xipser_Console (Jendela 1)"
    tmux send-keys -t mcbe_online:1 "cd $SERVER_DIR" C-m
    tmux send-keys -t mcbe_online:1 "LD_LIBRARY_PATH=. ./bedrock_server" C-m

    # Lampirkan ke sesi Tmux
    echo "Server Xipser telah berjalan di background (tmux)."
    echo ""
    echo "LANGKAH BERIKUTNYA:"
    echo "1. Tekan Ctrl+B lalu 0 untuk melihat Alamat IP dan Port Ngrok."
    echo "2. Tekan Ctrl+B lalu 1 untuk mengakses konsol server Xipser."
    echo "3. Untuk mematikan server dengan aman (wajib agar dunia tersimpan), masuk ke Jendela 1 dan ketik 'stop'."
    echo "4. Untuk keluar (detach) tanpa mematikan server, tekan Ctrl+B lalu d."
    echo "========================================================="
    tmux attach-session -t mcbe_online
}

# --- Main Logic ---
check_permissions

if [ "$1" == "add_admin" ]; then
    add_admin "$2"
else
    start_server
fi
