# Stage 1: Build flutter web app (đã làm ở bước trước)
# Bạn đã build rồi, nên có thể bỏ qua phần build lại bằng Flutter trong Docker
# Giờ chỉ cần serve static bằng nginx

FROM nginx:alpine

# Copy app đã build vào thư mục mặc định nginx
COPY build/web /usr/share/nginx/html

# Cấu hình lại nginx để xử lý route Flutter
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]