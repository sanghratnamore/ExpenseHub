package com.expensehub.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;

import java.io.InputStream;

@Component
@RequiredArgsConstructor
@Slf4j
public class FirebaseConfig {

    private final ResourceLoader resourceLoader;

    @Value("${firebase.service-account-path}")
    private String serviceAccountPath;

    @PostConstruct
    public void initializeFirebase() {

        try {
            if (!FirebaseApp.getApps().isEmpty()) {
                log.info("Firebase Admin SDK already initialized");
                return;
            }

            Resource resource = resourceLoader.getResource(serviceAccountPath);

            if (!resource.exists()) {
                throw new IllegalStateException(
                        "Firebase service account file not found at: "
                                + serviceAccountPath
                );
            }

            try (InputStream serviceAccount = resource.getInputStream()) {

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(
                                GoogleCredentials.fromStream(serviceAccount)
                        )
                        .build();

                FirebaseApp.initializeApp(options);

                log.info("Firebase Admin SDK initialized successfully");
            }

        } catch (Exception e) {
            throw new IllegalStateException(
                    "Failed to initialize Firebase Admin SDK. "
                            + "Check firebase.service-account-path: "
                            + serviceAccountPath,
                    e
            );
        }
    }
}