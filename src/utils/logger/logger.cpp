#include "logger.h"
#include <exception>
#include <iostream>

void neoshell::Logger::info(const std::string &value) {
  std::cout << "neoshell " << COLOR_GREEN << "[info]:" << value << COLOR_RESET << '\n';
}
void neoshell::Logger::critical(const std::string &value) {
  std::cout << "neoshell " << COLOR_RED << COLOR_BOLD << "[error]:" << value << COLOR_RESET << '\n';
}
void neoshell::Logger::error(const std::string &value) {
  std::cout << "neoshell " << COLOR_RED << "[error]:" << value << COLOR_RESET << std::endl;
}
void neoshell::Logger::error(const std::exception &value) {
  std::cout << "neoshell " << COLOR_RED << "[error]:" << value.what() << COLOR_RESET << std::endl;
}
void neoshell::Logger::warning(const std::string &value) {
  std::cout << "neoshell " << COLOR_YELLOW << "[warning]:" << value << COLOR_RESET << '\n';
}
void neoshell::Logger::debug(const std::string &value) {
    std::cout << "neoshell " << COLOR_CYAN << "[debug]: " << value << COLOR_RESET << '\n';
}
