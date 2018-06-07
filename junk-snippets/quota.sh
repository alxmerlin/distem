#!/bin/bash

if [[ $EUID > 0 ]]; then
    echo "Please run as root/sudo"
    exit 1
fi

create_cgroup(){
    if test -e "/sys/fs/cgroup/cpu,cpuacct/testcpu"; then
        echo "Cgroup alredy here"
        exit 1
    else
        echo Creating Cgroups
        mkdir "/sys/fs/cgroup/cpu,cpuacct/testcpu"
    fi
}

put_pid(){
    if test ! -e "/sys/fs/cgroup/cpu,cpuacct/testcpu"; then
        echo "the cgroup is note here"
        exit 1
    fi
    echo $PID > /sys/fs/cgroup/cpu,cpuacct/testcpu/tasks
    echo "Put $PID in cgroup"
}

put_limit(){
    if test ! -e "/sys/fs/cgroup/cpu,cpuacct/testcpu"; then
        echo "The cgroup is note here"
        exit 1
    fi
    period=$(cat /sys/fs/cgroup/cpu,cpuacct/testcpu/cpu.cfs_period_us)
    quota_us=$(perl -E "say $period*$RATIO")
    echo $quota_us > "/sys/fs/cgroup/cpu,cpuacct/testcpu/cpu.cfs_quota_us"
    echo "Limit quota in the cgroup ($RATIO=$quota_us÷$period)"
}

remove_cgroup(){
    if test ! -e "/sys/fs/cgroup/cpu,cpuacct/testcpu"; then
        echo "the cgroup is note here"
        exit 1
    fi
    cat /sys/fs/cgroup/cpu,cpuacct/testcpu/cgroup.procs | xargs -n 1 echo > /sys/fs/cgroup/cpu,cpuacct/cgroup.procs
    rmdir /sys/fs/cgroup/cpu,cpuacct/testcpu
    echo "removing cgroup"

}

if test $1 = "create"; then
    create_cgroup
    exit
elif test $1 = "delete"; then
    remove_cgroup
    exit
elif test $1 = "add"; then
    PID=$2
    put_pid
elif test $1 == "ratio"; then
    RATIO=$2
    put_limit
else
    echo "Usage: $0 [create, delete, add PID, ratio FRAQ]"
fi
