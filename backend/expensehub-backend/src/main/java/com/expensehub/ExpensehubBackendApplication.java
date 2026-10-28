package com.expensehub;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class ExpensehubBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(ExpensehubBackendApplication.class, args);
    }

}
