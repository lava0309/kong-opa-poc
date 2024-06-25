package com.redis.demo.controller;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/users")
public class RedisController {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @PostMapping("/{username}")
    public void createUser(@PathVariable String username, @RequestBody String json) {
        redisTemplate.opsForValue().set(username, json);
        redisTemplate.expire(username, 60, TimeUnit.MINUTES);
    }

    @PostMapping("/create/{username}")
    public void createUserData(@PathVariable String username) {
        String json = "{ \"rr\" : [\"BNSF\", \"UP\" , \"BMW\"] }";
        redisTemplate.opsForValue().set(username, json);
        redisTemplate.expire(username, 60, TimeUnit.MINUTES);
    }

    @GetMapping("/{username}")
    public String getUser(@PathVariable String username) {
        return (String) redisTemplate.opsForValue().get(username);
    }
}
