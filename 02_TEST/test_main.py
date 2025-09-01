#!/usr/bin/env python3
"""
Unit tests for main.py

This module contains comprehensive unit tests for all classes and functions
in the main application.
"""

import unittest
import sys
import os
import logging
from unittest.mock import patch, MagicMock
from pathlib import Path

# Import main module for testing
SRC = Path(__file__).parent.parent / "01_SRC"
sys.path.insert(0, str(SRC))
import main

from main import (
    AppConfig,
    ConfigurationError,
    load_configuration,
    get_default_config,
    validate_config,
    setup_logging,
    GreetingService,
    AppInfoService,
    log_startup_info,
    demonstrate_features,
    sanitize_input,
    is_sensitive_value,
    main,
)


class TestAppConfig(unittest.TestCase):
    """Test cases for AppConfig dataclass."""

    def test_app_config_creation(self):
        """Test creating AppConfig instance."""
        config = AppConfig(
            app_name="Test App",
            app_version="1.0.0",
            environment="development",
            debug=True,
            log_level="INFO",
        )
        self.assertEqual(config.app_name, "Test App")
        self.assertEqual(config.app_version, "1.0.0")
        self.assertEqual(config.environment, "development")
        self.assertTrue(config.debug)
        self.assertEqual(config.log_level, "INFO")


class TestConfiguration(unittest.TestCase):
    """Test cases for configuration management."""

    @patch.dict(
        os.environ,
        {
            "APP_NAME": "Test App",
            "APP_VERSION": "2.0.0",
            "APP_ENV": "production",
            "DEBUG": "true",
            "LOG_LEVEL": "DEBUG",
        },
    )
    @patch("main.Path.exists", return_value=True)
    @patch("main.load_dotenv")
    def test_load_configuration_with_env(self, mock_load_dotenv, mock_exists):
        """Test loading configuration with environment variables."""
        _ = mock_load_dotenv
        _ = mock_exists
        config = load_configuration()
        self.assertEqual(config.app_name, "Test App")
        self.assertEqual(config.app_version, "2.0.0")
        self.assertEqual(config.environment, "production")
        self.assertTrue(config.debug)
        self.assertEqual(config.log_level, "DEBUG")

    @patch("main.Path.exists", return_value=False)
    def test_load_configuration_no_env_file(self, mock_exists):
        """Test loading configuration when .env file doesn't exist."""
        _ = mock_exists
        with patch("main.logging.warning"):
            config = load_configuration()
            self.assertEqual(config.app_name, "Project Template")
            self.assertEqual(config.environment, "development")
            self.assertFalse(config.debug)

    @patch("main.Path.exists", return_value=True)
    @patch("main.load_dotenv", side_effect=ImportError("No module named 'dotenv'"))
    def test_load_configuration_dotenv_import_error(
        self, mock_load_dotenv, mock_exists
    ):
        """Test loading configuration when dotenv is not available."""
        _ = mock_load_dotenv
        _ = mock_exists
        with patch("main.logging.warning"):
            config = load_configuration()
            self.assertEqual(config.app_name, "Project Template")

    def test_get_default_config(self):
        """Test getting default configuration."""
        config = get_default_config()
        self.assertEqual(config.app_name, "Project Template")
        self.assertEqual(config.app_version, "1.0.0")
        self.assertEqual(config.environment, "development")
        self.assertFalse(config.debug)
        self.assertEqual(config.log_level, "INFO")

    def test_validate_config_valid(self):
        """Test validating valid configuration."""
        config = AppConfig(
            app_name="Test",
            app_version="1.0",
            environment="development",
            debug=False,
            log_level="INFO",
        )
        # Should not raise
        validate_config(config)

    def test_validate_config_invalid_log_level(self):
        """Test validating configuration with invalid log level."""
        config = AppConfig(
            app_name="Test",
            app_version="1.0",
            environment="development",
            debug=False,
            log_level="INVALID",
        )
        with self.assertRaises(ConfigurationError):
            validate_config(config)

    def test_validate_config_empty_app_name(self):
        """Test validating configuration with empty app name."""
        config = AppConfig(
            app_name="",
            app_version="1.0",
            environment="development",
            debug=False,
            log_level="INFO",
        )
        with self.assertRaises(ConfigurationError):
            validate_config(config)

    def test_validate_config_invalid_environment(self):
        """Test validating configuration with invalid environment."""
        config = AppConfig(
            app_name="Test",
            app_version="1.0",
            environment="invalid",
            debug=False,
            log_level="INFO",
        )
        with self.assertRaises(ConfigurationError):
            validate_config(config)

    def test_validate_config_empty_version(self):
        """Test validating configuration with empty version."""
        config = AppConfig(
            app_name="Test",
            app_version="",
            environment="development",
            debug=False,
            log_level="INFO",
        )
        with self.assertRaises(ConfigurationError):
            validate_config(config)

    def test_validate_config_whitespace_version(self):
        """Test validating configuration with whitespace version."""
        config = AppConfig(
            app_name="Test",
            app_version="   ",
            environment="development",
            debug=False,
            log_level="INFO",
        )
        with self.assertRaises(ConfigurationError):
            validate_config(config)

    def test_validate_config_invalid_semantic_version(self):
        """Test validating configuration with invalid semantic version."""
        invalid_versions = ["1", "1.0", "1.0.0.0", "1.0.0-beta", "v1.0.0", "1.0.0a"]
        for version in invalid_versions:
            with self.subTest(version=version):
                config = AppConfig(
                    app_name="Test",
                    app_version=version,
                    environment="development",
                    debug=False,
                    log_level="INFO",
                )
                with self.assertRaises(ConfigurationError):
                    validate_config(config)

    def test_validate_config_valid_semantic_versions(self):
        """Test validating configuration with valid semantic versions."""
        valid_versions = ["0.0.1", "1.0.0", "2.1.3", "10.20.30", "1.0.0", "999.999.999"]
        for version in valid_versions:
            with self.subTest(version=version):
                config = AppConfig(
                    app_name="Test",
                    app_version=version,
                    environment="development",
                    debug=False,
                    log_level="INFO",
                )
                # Should not raise
                validate_config(config)


class TestGreetingService(unittest.TestCase):
    """Test cases for GreetingService."""

    def setUp(self):
        """Set up test fixtures."""
        self.config = AppConfig(
            app_name="Test App",
            app_version="1.0.0",
            environment="development",
            debug=False,
            log_level="INFO",
        )
        self.service = GreetingService(self.config)

    def test_greet_valid_name(self):
        """Test greeting with valid name."""
        result = self.service.greet("Alice")
        self.assertEqual(result, "Hello, Alice! Welcome to Test App")

    def test_greet_name_with_spaces(self):
        """Test greeting with name containing spaces."""
        result = self.service.greet("John Doe")
        self.assertEqual(result, "Hello, John Doe! Welcome to Test App")

    def test_greet_name_with_hyphen(self):
        """Test greeting with name containing hyphen."""
        result = self.service.greet("Mary-Jane")
        self.assertEqual(result, "Hello, Mary-Jane! Welcome to Test App")

    def test_greet_name_with_apostrophe(self):
        """Test greeting with name containing apostrophe."""
        result = self.service.greet("O'Connor")
        self.assertEqual(result, "Hello, O'Connor! Welcome to Test App")

    def test_greet_empty_name(self):
        """Test greeting with empty name."""
        with self.assertRaises(ValueError):
            self.service.greet("")

    def test_greet_whitespace_only(self):
        """Test greeting with whitespace only."""
        with self.assertRaises(ValueError):
            self.service.greet("   ")

    def test_greet_non_string(self):
        """Test greeting with non-string input."""
        with self.assertRaises(ValueError):
            self.service.greet(123)

    def test_greet_name_too_long(self):
        """Test greeting with name longer than 50 characters."""
        long_name = "A" * 51
        with self.assertRaises(ValueError):
            self.service.greet(long_name)

    def test_greet_name_with_invalid_characters(self):
        """Test greeting with name containing invalid characters."""
        with self.assertRaises(ValueError):
            self.service.greet("Alice123")

    def test_greet_name_with_special_characters(self):
        """Test greeting with name containing special characters."""
        with self.assertRaises(ValueError):
            self.service.greet("Alice@")

    def test_greet_name_with_unicode_characters(self):
        """Test greeting with name containing unicode characters."""
        with self.assertRaises(ValueError):
            self.service.greet("Aliceñ")

    def test_greet_name_with_newlines(self):
        """Test greeting with name containing newlines."""
        with self.assertRaises(ValueError):
            self.service.greet("Alice\nBob")

    def test_greet_name_with_tabs(self):
        """Test greeting with name containing tabs."""
        with self.assertRaises(ValueError):
            self.service.greet("Alice\tBob")

    def test_greet_boundary_length(self):
        """Test greeting with boundary length names."""
        # Exactly 1 character
        result = self.service.greet("A")
        self.assertEqual(result, "Hello, A! Welcome to Test App")

        # Exactly 50 characters
        long_name = "A" * 50
        result = self.service.greet(long_name)
        self.assertEqual(result, f"Hello, {long_name}! Welcome to Test App")

    def test_get_multiple_greetings(self):
        """Test getting multiple greetings."""
        names = ["Alice", "Bob", "Charlie"]
        results = self.service.get_multiple_greetings(names)
        self.assertEqual(len(results), 3)
        self.assertIn("Hello, Alice!", results[0])
        self.assertIn("Hello, Bob!", results[1])
        self.assertIn("Hello, Charlie!", results[2])

    def test_get_multiple_greetings_empty_list(self):
        """Test getting multiple greetings with empty list."""
        results = self.service.get_multiple_greetings([])
        self.assertEqual(results, [])

    def test_get_multiple_greetings_with_invalid_names(self):
        """Test getting multiple greetings with some invalid names."""
        names = ["Alice", "", "Bob"]
        with self.assertRaises(ValueError):
            self.service.get_multiple_greetings(names)


class TestAppInfoService(unittest.TestCase):
    """Test cases for AppInfoService."""

    def setUp(self):
        """Set up test fixtures."""
        self.config = AppConfig(
            app_name="Test App",
            app_version="1.0.0",
            environment="development",
            debug=True,
            log_level="INFO",
        )
        self.service = AppInfoService(self.config)

    def test_get_app_info(self):
        """Test getting application information."""
        info = self.service.get_app_info()
        self.assertEqual(info["name"], "Test App")
        self.assertEqual(info["version"], "1.0.0")
        self.assertEqual(info["environment"], "development")
        self.assertTrue(info["debug_mode"])
        self.assertIn("python_version", info)
        self.assertIn("platform", info)


class TestLoggingFunctions(unittest.TestCase):
    """Test cases for logging functions."""

    def setUp(self):
        """Set up test fixtures."""
        self.config = AppConfig(
            app_name="Test App",
            app_version="1.0.0",
            environment="development",
            debug=False,
            log_level="INFO",
        )

    @patch("main.logging.basicConfig")
    def test_setup_logging(self, mock_basic_config):
        """Test setting up logging."""
        setup_logging(self.config)
        mock_basic_config.assert_called_once()

    @patch("main.logging.getLogger")
    def test_log_startup_info(self, mock_get_logger):
        """Test logging startup information."""
        mock_logger = MagicMock()
        mock_get_logger.return_value = mock_logger

        log_startup_info(self.config)

        # Verify logger.info was called multiple times
        self.assertGreater(mock_logger.info.call_count, 0)

    @patch("main.logging.getLogger")
    def test_demonstrate_features(self, mock_get_logger):
        """Test demonstrating features."""
        mock_logger = MagicMock()
        mock_get_logger.return_value = mock_logger

        greeting_service = GreetingService(self.config)
        app_info_service = AppInfoService(self.config)
        args = MagicMock()
        args.name = "Test"
        args.list_greetings = False

        demonstrate_features(greeting_service, app_info_service, args)

        # Verify logger.info was called
        self.assertGreater(mock_logger.info.call_count, 0)


class TestIntegration(unittest.TestCase):
    """Integration tests for the main application."""

    @patch.dict(
        os.environ,
        {
            "APP_NAME": "Integration Test App",
            "APP_VERSION": "1.0.0",
            "APP_ENV": "test",
            "DEBUG": "true",
            "LOG_LEVEL": "INFO",
        },
    )
    @patch("main.Path.exists", return_value=True)
    @patch("main.load_dotenv")
    @patch("main.logging.getLogger")
    @patch("main.sys.exit")
    def test_full_application_flow_with_typer(
        self, mock_exit, mock_get_logger, mock_load_dotenv, mock_exists
    ):
        """Test full application flow with typer CLI."""
        mock_logger = MagicMock()
        mock_get_logger.return_value = mock_logger

        # Mock typer to be available
        with patch("main.typer", create=True):
            # Import and test the main function
            typer_main = main.main

            # Mock typer context
            with patch("typer.Typer") as mock_typer_class:
                mock_app = MagicMock()
                mock_typer_class.return_value = mock_app

                # Call the typer main setup (this would normally be called by typer)
                typer_main.main()

                # Verify that typer app was created
                mock_typer_class.assert_called_once()

    @patch.dict(
        os.environ,
        {
            "APP_NAME": "Integration Test App",
            "APP_VERSION": "1.0.0",
            "APP_ENV": "test",
            "DEBUG": "false",
            "LOG_LEVEL": "INFO",
        },
    )
    @patch("main.Path.exists", return_value=True)
    @patch("main.load_dotenv")
    @patch("main.logging.getLogger")
    @patch("main.sys.exit")
    def test_full_application_flow_with_argparse(
        self, mock_exit, mock_get_logger, mock_load_dotenv, mock_exists
    ):
        """Test full application flow with argparse CLI."""
        mock_logger = MagicMock()
        mock_get_logger.return_value = mock_logger

        # Mock typer to be None (fallback to argparse)
        with patch("main.typer", None):
            with patch("main.parse_arguments") as mock_parse_args:
                # Mock parsed arguments
                mock_args = MagicMock()
                mock_args.name = "Test User"
                mock_args.verbose = False
                mock_args.list_greetings = True
                mock_parse_args.return_value = mock_args

                # Import and call main
                main.main()

                # Verify logging calls
                self.assertGreater(mock_logger.info.call_count, 0)
                mock_logger.info.assert_any_call("🚀 Starting application...")

    @patch.dict(os.environ, {"APP_NAME": "", "APP_VERSION": "1.0.0", "APP_ENV": "test"})
    @patch("main.Path.exists", return_value=True)
    @patch("main.load_dotenv")
    @patch("main.logging.getLogger")
    @patch("main.sys.exit")
    def test_application_handles_configuration_errors(
        self, mock_exit, mock_get_logger, mock_load_dotenv, mock_exists
    ):
        """Test that application handles configuration errors gracefully."""
        mock_logger = MagicMock()
        mock_get_logger.return_value = mock_logger

        with patch("main.typer", None):
            with patch("main.parse_arguments") as mock_parse_args:
                mock_args = MagicMock()
                mock_parse_args.return_value = mock_args

                main.main()

                # Verify error was logged and exit was called
                mock_logger.error.assert_called()
                mock_exit.assert_called_with(1)

    @patch("main.Path.exists", return_value=False)
    @patch("main.logging.getLogger")
    def test_application_runs_with_default_config(self, mock_get_logger, _mock_exists):
        """Test that application runs successfully with default configuration."""
        mock_logger = MagicMock()
        mock_get_logger.return_value = mock_logger

        with patch("main.typer", None):
            with patch("main.parse_arguments") as mock_parse_args:
                mock_args = MagicMock()
                mock_args.name = "Default User"
                mock_args.verbose = False
                mock_args.list_greetings = False
                mock_parse_args.return_value = mock_args

                main.main()

                # Verify success message was logged
                mock_logger.info.assert_any_call(
                    "\n✅ Application completed successfully!"
                )

    @patch.dict(
        os.environ,
        {
            "APP_NAME": "Keyboard Interrupt Test",
            "APP_VERSION": "1.0.0",
            "APP_ENV": "test",
        },
    )
    @patch("main.Path.exists", return_value=True)
    @patch("main.load_dotenv")
    @patch("main.logging.getLogger")
    @patch("main.sys.exit")
    def test_application_handles_keyboard_interrupt(
        self, mock_exit, mock_get_logger, mock_load_dotenv, mock_exists
    ):
        """Test that application handles keyboard interrupt gracefully."""
        mock_logger = MagicMock()
        mock_get_logger.return_value = mock_logger

        with patch("main.typer", None):
            with patch("main.parse_arguments") as mock_parse_args:
                mock_args = MagicMock()
                mock_parse_args.return_value = mock_args

                # Simulate KeyboardInterrupt during main execution
                with patch("main.load_configuration", side_effect=KeyboardInterrupt):
                    main.main()

                    mock_logger.info.assert_any_call(
                        "\n🛑 Application interrupted by user"
                    )
                    mock_exit.assert_called_with(0)


class TestSecurityFunctions(unittest.TestCase):
    """Test cases for security functions."""

    def test_sanitize_input_basic(self):
        """Test basic input sanitization."""
        self.assertEqual(sanitize_input("  hello  "), "hello")
        self.assertEqual(sanitize_input("hello\tworld"), "helloworld")
        self.assertEqual(sanitize_input("hello\nworld"), "helloworld")

    def test_sanitize_input_script_removal(self):
        """Test script tag removal."""
        input_str = "hello<script>alert('xss')</script>world"
        expected = "helloworld"
        self.assertEqual(sanitize_input(input_str), expected)

    def test_sanitize_input_html_stripping(self):
        """Test HTML stripping."""
        input_str = "<b>hello</b>"
        expected = "hello"
        self.assertEqual(sanitize_input(input_str, strip_html=True), expected)

    def test_sanitize_input_length_limit(self):
        """Test length limiting."""
        input_str = "verylongstring"
        expected = "veryl"
        self.assertEqual(sanitize_input(input_str, max_length=5), expected)

    def test_sanitize_input_non_string(self):
        """Test non-string input raises error."""
        with self.assertRaises(ValueError):
            sanitize_input(123)

    def test_is_sensitive_value_sensitive_keys(self):
        """Test detection of sensitive keys."""
        self.assertTrue(is_sensitive_value("DB_PASSWORD", "secret123"))
        self.assertTrue(is_sensitive_value("API_KEY", "key123"))
        self.assertTrue(is_sensitive_value("JWT_SECRET", "token"))

    def test_is_sensitive_value_base64(self):
        """Test detection of base64-like values."""
        self.assertTrue(is_sensitive_value("SOME_VAR", "SGVsbG8gV29ybGQ="))

    def test_is_sensitive_value_hex(self):
        """Test detection of hex values."""
        hex_value = "a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3"
        self.assertTrue(is_sensitive_value("HASH", hex_value))

    def test_is_sensitive_value_normal_values(self):
        """Test that normal values are not flagged."""
        self.assertFalse(is_sensitive_value("APP_NAME", "My App"))
        self.assertFalse(is_sensitive_value("PORT", "3000"))

    def test_rate_limiter_allow_within_limit(self):
        """Test rate limiter allows requests within limit."""
        limiter = main.RateLimiter(1000, 2)  # 1 second, 2 requests
        self.assertTrue(limiter.is_allowed("user1"))
        self.assertTrue(limiter.is_allowed("user1"))

    def test_rate_limiter_block_over_limit(self):
        """Test rate limiter blocks requests over limit."""
        limiter = main.RateLimiter(1000, 2)
        limiter.is_allowed("user1")
        limiter.is_allowed("user1")
        self.assertFalse(limiter.is_allowed("user1"))

    def test_rate_limiter_remaining_requests(self):
        """Test tracking of remaining requests."""
        limiter = main.RateLimiter(1000, 3)
        self.assertEqual(limiter.get_remaining_requests("user1"), 3)
        limiter.is_allowed("user1")
        self.assertEqual(limiter.get_remaining_requests("user1"), 2)


if __name__ == "__main__":
    # Set up logging for tests
    logging.basicConfig(level=logging.DEBUG)

    # Run tests
    unittest.main()
