package com.expensehub.security;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        final String jwt = authHeader.substring(7);

        try {
            final String userEmail = jwtService.extractEmail(jwt);

            if (userEmail != null &&
                    SecurityContextHolder.getContext().getAuthentication() == null) {

                try {
                    UserDetails userDetails =
                            userDetailsService.loadUserByUsername(userEmail);

                    if (jwtService.isTokenValid(jwt, userEmail)) {

                        UsernamePasswordAuthenticationToken authToken =
                                new UsernamePasswordAuthenticationToken(
                                        userDetails,
                                        null,
                                        userDetails.getAuthorities()
                                );

                        authToken.setDetails(
                                new WebAuthenticationDetailsSource()
                                        .buildDetails(request)
                        );

                        SecurityContextHolder.getContext()
                                .setAuthentication(authToken);
                    }

                } catch (UsernameNotFoundException exception) {
                    writeUnauthorizedResponse(
                            response,
                            "USER_NOT_FOUND",
                            "Invalid or expired token. Please log in again."
                    );
                    return;
                }
            }

            filterChain.doFilter(request, response);

        } catch (ExpiredJwtException exception) {
            writeUnauthorizedResponse(
                    response,
                    "TOKEN_EXPIRED",
                    "Session expired. Please log in again."
            );
        } catch (JwtException | IllegalArgumentException exception) {
            writeUnauthorizedResponse(
                    response,
                    "INVALID_TOKEN",
                    "Invalid authentication token."
            );
        }
    }

    private void writeUnauthorizedResponse(
            HttpServletResponse response,
            String error,
            String message
    ) throws IOException {

        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        response.getWriter().write(
                "{\"error\":\"" + error + "\"," +
                        "\"message\":\"" + message + "\"}"
        );
    }
}