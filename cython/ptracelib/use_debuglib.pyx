from libc.string cimport memset
from posix.wait cimport wait
from posix.types cimport pid_t
import os

cdef extern from "sys/ptrace.h" nogil: # TODO need nogil?
    enum __ptrace_request:
        pass
    long ptrace(__ptrace_request request, pid_t pid, \
                   void *addr, void *data)
    __ptrace_request PTRACE_CONT

cdef extern from "debuglib.h":
    long get_child_eip(pid_t pid)
    ctypedef struct debug_breakpoint: # TODO what is in here
        void* addr "addr"
        unsigned orig_data "orig_data"
    debug_breakpoint* create_breakpoint(pid_t pid, void* addr)
    int resume_from_breakpoint(pid_t pid, debug_breakpoint* bp)
    void cleanup_breakpoint(debug_breakpoint* bp)
    void run_target(const char* programname)
    int wait_common()
    int step_one(pid_t pid, debug_breakpoint* bp)


cdef debug_breakpoint* bp_global
cdef int blah = 0

def pycreate_breakpoint(int child_pid, int loc):
    global bp_global
    global blah
    bp_global = create_breakpoint(child_pid, <void*> loc)
    #bp_global = create_breakpoint(child_pid, <void*>0x8048414)
    blah = 999

def pycontinue(int child_pid):
    ptrace(PTRACE_CONT, child_pid, NULL, NULL)

def pywait():
    return wait_common()

def pycleanup_breakpoint():
    global bp_global
    cleanup_breakpoint(bp_global)

def pyresume_from_breakpoint(int child_pid):
    global bp_global
    return resume_from_breakpoint(child_pid, bp_global)

def pyrun_target(char* progname):
    run_target(progname)

def pystep(int child_pid):
    return step_one(child_pid, bp_global)

# TODO more efficient (code wise) way to wrap these c calls?
def pyget_child_eip(int child_pid):
    return get_child_eip(child_pid)
