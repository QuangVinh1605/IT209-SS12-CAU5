package com.example.demo;

import com.example.demo.controller.HelloController;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class DemoApplicationTests {

    @Autowired
    private HelloController helloController;

    @Test
    @DisplayName("Kiểm tra Spring Context khởi tạo thành công")
    void contextLoads() {
        assertNotNull(helloController, "HelloController phải được inject thành công");
    }

    @Test
    @DisplayName("Kiểm tra API Health trả về OK")
    void testHealthEndpoint() {
        String result = helloController.health();
        assertEquals("OK", result, "Health endpoint phải trả về chuỗi 'OK'");
    }

    @Test
    @DisplayName("Kiểm tra API Index trả về status UP")
    void testIndexEndpoint() {
        Map<String, Object> response = helloController.index();
        assertEquals("UP", response.get("status"));
        assertTrue(response.containsKey("message"));
    }
}
