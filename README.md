# x-ui
Hỗ trợ bảng điều khiển đa năng đa giao thức

# Đặc trưng
- Giám sát trạng thái hệ thống
- Hỗ trợ đa giao thức nhiều người dùng, hoạt động trực quan trên mạng
- Giao thức được hỗ trợ: Vmess, VMess, Trojan, Shadowsocks, Dokodemo-Door, Vớ, HTTP
- Hỗ trợ cấu hình nhiều cấu hình truyền
- Thống kê giao thông, lưu lượng truy cập hạn chế, thời gian hết hạn giới hạn
- Tùy chỉnh mẫu cấu hình xray
- Hỗ trợ Bảng truy cập HTTPS (Tên miền tự cung cấp + Chứng chỉ SSL)
- Các mục cấu hình nâng cao hơn, xem bảng để biết chi tiết

# 安装 安装 & nâng cấp
```
bash <(curl -Ls https://raw.githubusercontent.com/hotrantien01/x-ui/master/install.sh)
```

## Cài đặt & nâng cấp thủ công
1. Đầu tiên từ. https://github.com/hotrantien01/x-ui/releases Tải xuống gói nén mới nhất, thường chọn kiến ​​trúc `amd64`
2. Sau đó tải gói nén này vào thư mục `/ root /` của máy chủ và sử dụng máy chủ đăng nhập người dùng `root`

> Nếu kiến ​​trúc CPU máy chủ của bạn không phải là `amd64`, nó sẽ thay thế` amd64 vào lệnh cho các kiến ​​trúc khác.

```
cd /root/
rm x-ui/ /usr/local/x-ui/ /usr/bin/x-ui -rf
tar zxvf x-ui-linux-amd64.tar.gz
chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
cp x-ui/x-ui.sh /usr/bin/x-ui
cp -f x-ui/x-ui.service /etc/systemd/system/
mv x-ui/ /usr/local/
systemctl daemon-reload
systemctl enable x-ui
systemctl restart x-ui
```

## Cài đặt bằng Docker

> Hướng dẫn Docker này là với hình ảnh Docker[Chasing66](https://github.com/Chasing66)cung cấp

1. Cài đặt Docker
```shell
curl -fsSL https://get.docker.com | sh
```
2. Cài đặt X-UI
```shell
mkdir x-ui && cd x-ui
docker run -itd --network=host \
    -v $PWD/db/:/etc/x-ui/ \
    -v $PWD/cert/:/root/cert/ \
    --name x-ui --restart=unless-stopped \
    enwaiax/x-ui:latest
```
>Build Gương riêng
```shell
docker build -t x-ui .
```

## Hệ thống đề nghị
- CentOS 7+
- Ubuntu 16+
- Debian 8+

# vấn đề thường gặp

## 从 v2-ui di cư
Lần đầu tiên cài đặt phiên bản X-UI mới nhất trên máy chủ được cài đặt trong V2-UI, sau đó sử dụng lệnh sau để di chuyển, sẽ di chuyển máy này v2-ui` tất cả dữ liệu tài khoản trong nước` thành X-UI, `Cài đặt bảng điều khiển, và mật khẩu tên người dùng sẽ không di chuyển`
> Sau khi di chuyển thành công, vui lòng đóng v2-ui` và` khởi động lại X-UI`, nếu không, trong đó sẽ tạo ra xung đột cổng với X-UI InBound`
`` `.
x-ui v2-ui
```

## issue Khép kín
Các vấn đề nhỏ màu trắng khác nhau có huyết áp cao

## Stargazers over time

[![Stargazers over time](https://starchart.cc/hotrantien01/x-ui.svg)](https://starchart.cc/hotrantien01/x-ui)
