#include <signal.h>

int main() {
    sigset_t mask;
    sigsuspend(&mask);

    return 0;
}
