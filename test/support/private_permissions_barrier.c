// Test-only native blocking/error fixture. Never linked into the application.
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdatomic.h>
#include <string.h>
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
  if ((value == 1 || value == 4) && pipe2(gate, O_CLOEXEC)) return -1;
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
  if (mode >= 4 && !(flags & O_PATH)) { errno = EACCES; return -1; }
  int fd = real(path, flags);
  if (fd >= 0) { opened_fd = fd; ++opens; }
  return fd;
}
int statx(int fd, const char* path, int flags, unsigned mask, struct statx* buffer) {
  int (*real)(int, const char*, int, unsigned, struct statx*) = dlsym(RTLD_NEXT, "statx");
  if (mode == 7) { errno = EIO; return -1; }
  if (mode == 8) { memset(buffer, 0, sizeof(*buffer)); return 0; }
  return real(fd, path, flags, mask, buffer);
}
static int before_chmod(void) {
  worker_tid = syscall(SYS_gettid);
  ++entered;
  if (mode == 1 || mode == 4) {
    char value;
    ssize_t n;
    do { n = read(gate[0], &value, 1); } while (n < 0 && errno == EINTR);
    if (n != 1) return -1;
    mode = 0;
  }
  if (mode == 2 || mode == 5) { errno = EPERM; return -1; }
  return 0;
}
int fchmod(int fd, mode_t bits) {
  int (*real)(int, mode_t) = dlsym(RTLD_NEXT, "fchmod");
  if (before_chmod()) return -1;
  return real(fd, bits);
}
int chmod(const char* path, mode_t bits) {
  int (*real)(const char*, mode_t) = dlsym(RTLD_NEXT, "chmod");
  if (before_chmod()) return -1;
  return real(path, bits);
}
int close(int fd) {
  int (*real)(int) = dlsym(RTLD_NEXT, "close");
  int result = real(fd);
  if (fd == opened_fd && result == 0) ++closes;
  if (fd == opened_fd && (mode == 3 || mode == 6)) { errno = EIO; return -1; }
  return result;
}
