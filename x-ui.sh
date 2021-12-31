#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Sai lầm: ${plain} Bạn phải chạy tập lệnh này bằng người dùng root!\n" && exit 1

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

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Có khởi động lại bảng điều khiển, khởi động lại bảng cũng sẽ khởi động lại xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Nhấn ENTER để quay lại menu chính: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/hotrantien01/x-ui-vh/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "Tính năng này sẽ buộc phiên bản mới nhất hiện tại, dữ liệu sẽ không bị mất, nó có đang diễn ra không?" "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}Hủy bỏ${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/hotrantien01/x-ui-vh/master/install.sh)
    if [[ $? == 0 ]]; then
        echo -e "${green}Cập nhật hoàn thành, Bảng điều khiển khởi động lại tự động${plain}"
        exit 0
    fi
}

uninstall() {
    confirm "Bạn có muốn gỡ cài đặt bảng điều khiển, sẽ gỡ cài đặt Xray không?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "Gỡ cài đặt thành công, nếu bạn muốn xóa tập lệnh này, hãy hết sau khi chạy ${green}rm /usr/bin/x-ui -f${plain} 进行删除"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "Bạn có phải đặt lại tên người dùng và mật khẩu cho quản trị viên?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -username admin -password admin
    echo -e "Tên người dùng và mật khẩu đã được đặt lại thành ${green}admin${plain}，Vui lòng khởi động lại bảng điều khiển ngay bây giờ"
    confirm_restart
}

reset_config() {
    confirm "Hãy chắc chắn để thiết lập lại tất cả các cài đặt bảng, dữ liệu tài khoản sẽ không bị mất, tên người dùng và mật khẩu sẽ không thay đổi" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "Tất cả các cài đặt bảng đã được đặt lại về mặc định, bây giờ hãy khởi động lại bảng điều khiển và sử dụng mặc định ${green}1103${plain} Bảng truy cập cổng"
    confirm_restart
}

set_port() {
    echo && echo -n -e "Cổng đầu vào số[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        echo -e "${yellow}Hủy bỏ${plain}"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "Đặt cổng được hoàn thành, bây giờ khởi động lại bảng điều khiển và sử dụng cổng mới được đặt ${green}${port}${plain} Bảng truy cập"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}Bảng điều khiển đã chạy mà không bắt đầu lại. Nếu bạn cần khởi động lại, vui lòng chọn Khởi động lại.${plain}"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}x-ui Bắt đầu thành công${plain}"
        else
            echo -e "${red}Bảng điều khiển bắt đầu thất bại, có thể là do thời gian khởi động đã vượt quá hai giây, vui lòng kiểm tra thông tin nhật ký sau.${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        echo -e "${green}Bảng điều khiển đã dừng lại mà không dừng lại.${plain}"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green}x-ui Dừng thành công với xray${plain}"
        else
            echo -e "${red}Bảng điều khiển dừng thất bại, có thể là do thời gian dừng hơn hai giây, vui lòng kiểm tra thông tin nhật ký sau.${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}x-ui Khởi động lại với Xray thành công${plain}"
    else
        echo -e "${red}Bảng điều khiển được khởi động lại, có thể là do thời gian khởi động nhiều hơn hai giây, vui lòng kiểm tra thông tin nhật ký sau.${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}x-ui Đặt sự tự khởi động khởi động${plain}"
    else
        echo -e "${red}x-ui Đặt tự đánh bại khởi động${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}x-ui Hủy bỏ bắt đầu bắt đầu${plain}"
    else
        echo -e "${red}x-ui Hủy khởi động và tự thất bại${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u x-ui.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

migrate_v2_ui() {
    /usr/local/x-ui/x-ui v2-ui

    before_show_menu
}

install_bbr() {
    # temporary workaround for installing bbr
    bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
    echo ""
    before_show_menu
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/hotrantien01/x-ui-vh/raw/master/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Tải xuống kịch bản không thành công, vui lòng kiểm tra xem đơn vị có thể kết nối nếu đơn vị có thể kết nối không Github${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        echo -e "${green}Tập lệnh nâng cấp thành công, vui lòng chạy lại tập lệnh${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}Không lặp lại cài đặt bảng cài đặt.${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Vui lòng cài đặt bảng điều khiển đầu tiên${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Bảng điều khiển trạng thái: ${green}Chạy${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Bảng điều khiển trạng thái: ${yellow}Không chạy${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Bảng điều khiển trạng thái: ${red}Chưa cài đặt${plain}"
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Cho dù là khởi động: ${green}是${plain}"
    else
        echo -e "Cho dù là khởi động: ${red}否${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "xray trạng thái: ${green}chạy${plain}"
    else
        echo -e "xray trạng thái: ${red}Không chạy${plain}"
    fi
}

show_usage() {
    echo "x-ui Quản lý kịch bản cách sử dụng: "
    echo "------------------------------------------"
    echo "x-ui              - Menu quản lý hiển thị (nhiều tính năng hơn)"
    echo "x-ui start        - Bắt đầu bảng điều khiển X-UI"
    echo "x-ui stop         - Dừng bảng X-UI"
    echo "x-ui restart      - Khởi động lại bảng X-UI"
    echo "x-ui status       - Xem trạng thái X-UI"
    echo "x-ui enable       - Đặt Tự khởi động khởi động X-UI"
    echo "x-ui disable      - Hủy khởi động X-UI tự khởi động"
    echo "x-ui log          - Xem nhật ký X-UI"
    echo "x-ui v2-ui        - Di chuyển dữ liệu tài khoản V2-UI của máy này sang X-UI"
    echo "x-ui update       - Cập nhật bảng X-UI"
    echo "x-ui install      - Cài đặt bảng điều khiển X-UI"
    echo "x-ui uninstall    - Gỡ cài đặt bảng X-UI"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}x-ui Kịch bản quản lý bảng điều khiển${plain}
  ${green}0.${plain} Thoát kịch bản
————————————————
  ${green}1.${plain} Cài đặt X-UI
  ${green}2.${plain} Cập nhật X-UI
  ${green}3.${plain} Gỡ cài đặt X-UI
————————————————
  ${green}4.${plain} Đặt lại mật khẩu tên người dùng
  ${green}5.${plain} Đặt lại cài đặt bảng điều khiển
  ${green}6.${plain} Đặt bảng điều khiển
————————————————
  ${green}7.${plain} Bắt đầu X-UI
  ${green}8.${plain} Dừng X-UI
  ${green}9.${plain} X-UI nghiêm túc
 ${green}10.${plain} Xem trạng thái X-UI
 ${green}11.${plain} Xem nhật ký X-UI
————————————————
 ${green}12.${plain} Đặt Tự khởi động khởi động X-UI
 ${green}13.${plain} Hủy khởi động X-UI tự khởi động
————————————————
 ${green}14.${plain} 一Chìa khóa để cài đặt BBR (Kernel mới nhất)
 "
    show_status
    echo && read -p "Vui lòng nhập lựa chọn [0-14]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && reset_user
        ;;
        5) check_install && reset_config
        ;;
        6) check_install && set_port
        ;;
        7) check_install && start
        ;;
        8) check_install && stop
        ;;
        9) check_install && restart
        ;;
        10) check_install && status
        ;;
        11) check_install && show_log
        ;;
        12) check_install && enable
        ;;
        13) check_install && disable
        ;;
        14) install_bbr
        ;;
        *) echo -e "${red}Vui lòng nhập đúng số [0-14]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "v2-ui") check_install 0 && migrate_v2_ui 0
        ;;
        "update") check_install 0 && update 0
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        *) show_usage
    esac
else
    show_menu
fi
