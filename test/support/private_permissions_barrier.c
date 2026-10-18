// Test-only native blocking/error fixture. Never linked into the application.
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdatomic.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>

static int gate[2] = {-1, -1};
static atomic_int mode, entered, opens, closes, worker_tid;
static int opened_fd = -1;
int permission_test_configure(int value) {
  if (gate[0] >= 0) close(gate[0]);
  if (gate[1] >= 0) close(gate[1]);
  gate[0] = gate[1] = -1;
  entered = opens = closes = worker_tid = 0;
  opened_fd = -1;
  if (value == 1 && pipe2(gate, O_CLOEXEC)) return -1;
  mode = value;
  return 0;
}
int permission_test_entered(void) { return entered; }
int permission_test_opens(void) { return opens; }
int permission_test_closes(void) { return closes; }
int permission_test_worker_tid(void) { return worker_tid; }
int permission_test_current_tid(void) { return syscall(SYS_gettid); }
int permission_test_release(void) { return write(gate[1], "x", 1); }
int open(const char* path, int flags, ...) {
  int (*real)(const char*, int) = dlsym(RTLD_NEXT, "open");
  int fd = real(path, flags);
  if (fd >= 0) { opened_fd = fd; ++opens; }
  return fd;
}
int fchmod(int fd, mode_t bits) {
  int (*real)(int, mode_t) = dlsym(RTLD_NEXT, "fchmod");
  worker_tid = syscall(SYS_gettid);
  ++entered;
  if (mode == 1) {
    char value;
    ssize_t n;
    do { n = read(gate[0], &value, 1); } while (n < 0 && errno == EINTR);
    if (n != 1) return -1;
    mode = 0;
  }
  if (mode == 2) { errno = EPERM; return -1; }
  return real(fd, bits);
}
int close(int fd) {
  int (*real)(int) = dlsym(RTLD_NEXT, "close");
  int result = real(fd);
  if (fd == opened_fd && result == 0) ++closes;
  if (fd == opened_fd && mode == 3) { errno = EIO; return -1; }
  return result;
}
