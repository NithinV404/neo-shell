#include "logger.hpp"
#include <exception>
#include <iostream>
#include <ostream>

void Logger::info(const std::string &value) {
  std::cout << "neoshell " << COLOR_GREEN << "[info]:" << value << COLOR_RESET << '\n';
}
void Logger::critical(const std::string &value) {
  std::cout << "neoshell " << COLOR_RED << COLOR_BOLD << "[error]:" << value << COLOR_RESET << '\n';
}
void Logger::error(const std::string &value) {
  std::cout << "neoshell " << COLOR_RED << "[error]:" << value << COLOR_RESET << std::endl;
}
void Logger::error(const std::exception &value) {
  std::cout << "neoshell " << COLOR_RED << "[error]:" << value.what() << COLOR_RESET << std::endl;
}
void Logger::warning(const std::string &value) {
  std::cout << "neoshell " << COLOR_YELLOW << "[warning]:" << value << COLOR_RESET << '\n';
}
void Logger::debug(const std::string &value) {
    std::cout << "neoshell " << COLOR_CYAN << "[debug]: " << value << COLOR_RESET << '\n';
}
