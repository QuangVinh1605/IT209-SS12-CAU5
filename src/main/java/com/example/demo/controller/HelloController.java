package com.example.demo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
public class HelloController {

    @GetMapping("/")
    public Map<String, Object> index() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("message", "DevOps Session 11 - CI/CD Pipeline Spring Boot Application");
        return response;
    }

    @GetMapping("/api/health")
    public String health() {
        return "OK";
    }
}
