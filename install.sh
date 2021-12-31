#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Sai lầm：${plain} Bạn phải chạy tập lệnh này bằng người dùng root！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Không có phiên bản hệ thống được phát hiện, vui lòng liên hệ với tác giả của kịch bản！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64"
else
  arch="amd64"
  echo -e "${red}Phát hiện kiến ​​trúc không thành công, sử dụng kiến ​​trúc mặc định: ${arch}${plain}"
fi

echo "Ngành kiến ​​trúc: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ] ; then
    echo "Phần mềm này không hỗ trợ các hệ thống 32 bit (x86), vui lòng sử dụng hệ thống 64 bit (x86_64), nếu phát hiện không chính xác, vui lòng liên hệ với tác giả."
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Vui lòng sử dụng CentOS 7 hoặc hệ thống cao hơn！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ thống Ubuntu 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ thống Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/hotrantien01/x-ui-vh/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Phát hiện phiên bản X-UI không thành công, có thể vượt quá các hạn chế API của GitHub, vui lòng thử lại sau hoặc chỉ định thủ công cài đặt phiên bản X-UI.${plain}"
            exit 1
        fi
        echo -e "Đã phát hiện phiên bản mới nhất của X-UI：${last_version}，Bắt đầu cài đặt"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/hotrantien01/x-ui-vh/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Tải xuống X-UI không thành công, hãy đảm bảo máy chủ của bạn có thể tải xuống tệp của GitHub${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/hotrantien01/x-ui-vh/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "Bắt đầu cài đặt x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Tải xuống X-UI v$1 Thất bại, đảm bảo phiên bản này tồn tại${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/hotrantien01/x-ui-vh/main/x-ui.sh
    chmod +x /usr/bin/x-ui
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui v${last_version}${plain} Việc cài đặt đã hoàn tất, bảng điều khiển đã bắt đầu，"
    echo -e ""
    echo -e "Để cài đặt mới, cổng mặc định cho web ${green}1103${plain}，Tên người dùng và mật khẩu là mặc định ${green}admin${plain}"
    echo -e "Đảm bảo rằng cổng này khôngVà đảm bảo rằng cảng 1103 đã được phát hànhi một chương trình riêng khác，${yellow}并且确保 1103 端口已放行${plain}"
#    echo -e "若想将 1103 修改为其它端口，输入 x-ui 命令进行修改，同样也要确保你修改的端口也是放行的"
    echo -e ""
    echo -e "Nếu bạn là một bảng cập nhật, hãy bấm cách trước để truy cập bảng điều khiển."
    echo -e ""
    echo -e "x-ui Quản lý kịch bản Cách sử dụng: "
    echo -e "----------------------------------------------"
    echo -e "x-ui              - Menu quản lý hiển thị (nhiều tính năng hơn)"
    echo -e "x-ui start        - Bắt đầu bảng điều khiển X-UI"
    echo -e "x-ui stop         - Dừng bảng X-UI"
    echo -e "x-ui restart      - Khởi động lại bảng X-UI"
    echo -e "x-ui status       - Xem trạng thái X-UI"
    echo -e "x-ui enable       - Đặt Tự khởi động khởi động X-UI"
    echo -e "x-ui disable      - Hủy khởi động X-UI tự khởi động"
    echo -e "x-ui log          - Xem nhật ký X-UI"
    echo -e "x-ui v2-ui        - Di chuyển dữ liệu tài khoản V2-UI của máy này sang x-ui"
    echo -e "x-ui update       - Cập nhật bảng X-UI"
    echo -e "x-ui install      - Cài đặt bảng điều khiển X-UI"
    echo -e "x-ui uninstall    - Gỡ cài đặt bảng X-UI"
    echo -e "----------------------------------------------"
}

echo -e "${green}Bắt đầu cài đặt${plain}"
install_base
install_x-ui $1
