
由于最近发现我用的openwrt没有带no-ip.com的v6ddns更新,就写了一个脚本(无需参数),进行更新.

运行环境是个ubuntu lxd虚拟机

具体实现功能:

通过访问curl -4 ip.sb 和curl -6 ip.sb 来获得当前的双栈ip, 和域名的双栈ip比较,

如果ip之一改变了,就进行更新.

它的更新是API:

curl -u "{username}:{password}" https://dynupdate.no-ip.com/nic/update?hostname={hostname}&myip={ipaddress}
