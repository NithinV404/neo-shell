#pragma once
#include <exception>
#include <sstream>
#include <string>

class Logger {
    private:

        Logger() = default;

        // ANSI Escape Codes for Colors
        bool set_debug = false;
        static constexpr const char* COLOR_RESET   = "\033[0m";
        static constexpr const char* COLOR_GREEN   = "\033[32m";
        static constexpr const char* COLOR_YELLOW  = "\033[33m";
        static constexpr const char* COLOR_RED     = "\033[31m";
        static constexpr const char* COLOR_CYAN    = "\033[36m";
        static constexpr const char* COLOR_BOLD    = "\033[1m";
    public:
        // Public logger methods

        Logger(const Logger&) = delete;
        Logger& operator = (const Logger&) = delete;

        static Logger& getInstance() {
            static Logger instance;
            return instance;
        }

        void info(const std::string &value);
        void warning(const std::string &value);
        void critical(const std::string &value);
        void error(const std::string &value);
        void error(const std::exception &value);
        void debug(const std::string &value);


        template<typename T>
        void debug(const T &value) {
            std::ostringstream ss;
            ss << value;
            debug(ss.str());
        }

        template<typename T>
        void info(const T &value) {
            std::ostringstream ss;
            ss << value;
            info(ss.str());
        }
};
