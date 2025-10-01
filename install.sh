#!/data/data/com.termux/files/usr/bin/bash

# =========================================================
# Skrip Instalasi Otomatis Minecraft Bedrock Server (BDS)
# Versi Server: 1.21.102.1 (Terbaru saat ini)
# Output: Membuat file start.sh di direktori $HOME
# =========================================================

# Variabel Global
NGROK_TOKEN="33RKXoLi8mLMccvpJbo1LoN3fCg_4AEGykdpBZeXx2TFHaCQj"
MCBE_VERSION="1.21.102.1"
MCBE_SERVER_URL="https://minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${MCBE_VERSION}.zip"
MC_PORT=19132
SERVER_DIR="$HOME/mcbe_server"
NGROK_ZIP="ngrok-stable-linux-arm64.zip"

echo "========================================================="
echo "           🚀 Memulai Instalasi Server XIPSER (BDS)      "
echo "========================================================="

# --- 1. Persiapan Termux dan Paket ---
echo "[1/4] Memperbarui Termux dan menginstal paket penting..."
pkg update -y
pkg install wget unzip tmux libcurl -y

# --- 2. Instalasi dan Otentikasi Ngrok ---
echo "[2/4] Mengunduh dan menyiapkan Ngrok..."
if [ ! -f "$HOME/ngrok" ]; then
    wget "https://bin.equinox.io/c/4VmDzA7iaHb/${NGROK_ZIP}" -O ngrok.zip
    unzip ngrok.zip
    rm ngrok.zip
fi
chmod +x ngrok

echo "    -> Otentikasi Ngrok..."
./ngrok authtoken "${NGROK_TOKEN}"

# --- 3. Instalasi dan Konfigurasi Server BDS ---
echo "[3/4] Mengunduh dan mengkonfigurasi Server Bedrock v${MCBE_VERSION}..."
mkdir -p "$SERVER_DIR"
cd "$SERVER_DIR"

# Download dan ekstrak Bedrock Server
wget "$MCBE_SERVER_URL" -O bedrock_server.zip
unzip -o bedrock_server.zip # -o: overwrite
rm bedrock_server.zip
chmod +x bedrock_server

# Jalankan server sebentar untuk membuat file konfigurasi (EULA, properties)
if [ ! -f server.properties ]; then
    echo "    -> Menjalankan server sebentar untuk membuat file konfigurasi awal..."
    LD_LIBRARY_PATH=. ./bedrock_server &
    SERVER_PID=$!
    sleep 5
    kill "$SERVER_PID" 2>/dev/null
    sleep 1
fi

# Mengatur nama server menjadi "Xipser" dan menyetujui EULA
echo "    -> Mengatur nama server menjadi 'Xipser'..."
sed -i 's/server-name=.*/server-name=Xipser/' server.properties
echo "eula=true" > eula.txt # Pastikan EULA disetujui

# Kembali ke home Termux
cd "$HOME"

# --- 4. Membuat Skrip Peluncuran (start.sh) ---
echo "[4/4] Membuat skrip peluncuran start.sh di $HOME..."
cat > start.sh << 'START_EOF'
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
    echo "Setelah itu, ketik 'exit' untuk kembali ke menu utama."
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
START_EOF

# Set izin eksekusi untuk start.sh
chmod +x start.sh

echo "========================================================="
echo "✅ Instalasi XIPSER Server SELESAI!"
echo "---------------------------------------------------------"
echo "Sekarang, Anda bisa kembali ke direktori HOME dan menjalankan server:"
echo "cd"
echo "./start.sh"
echo ""
echo "💡 Untuk menambahkan admin, jalankan:"
echo "./start.sh add_admin [Nama_GamerTag]"
echo "========================================================="
