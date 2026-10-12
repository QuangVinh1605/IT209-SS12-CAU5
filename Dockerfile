# ==============================================================================
# Dockerfile cho Spring Boot Application (Session 11 - Bài 5)
# Sử dụng base image JRE 17 Alpine siêu nhẹ, tối ưu bảo mật và kích thước
# ==============================================================================
FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="QuangVinh1605" \
      description="Spring Boot Gradle Application for DevOps CI/CD Pipeline"

WORKDIR /app

# Tạo user không đặc quyền để tăng cường bảo mật container
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Sao chép tệp JAR đã được đóng gói từ Job test
COPY build/libs/app.jar app.jar

# Phân quyền cho appuser
RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app/app.jar"]
