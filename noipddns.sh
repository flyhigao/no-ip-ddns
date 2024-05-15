#!/bin/sh

# 设置您的 No-IP 用户名和密码
username="your no-ip username"
password="your no-ip password"

# 设置您的no-ip域名
hostname="change--yourdomain.ddns.net--change"

# 设置日志文件路径
log_file="/opt/noipddns.log"

# 定义检查 IP 格式的函数
check_ip() {
  local ip_address=$1
  if ! echo "$ip_address" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' && ! echo "$ip_address" | grep -qE '^([0-9a-fA-F:]+:+)+[0-9a-fA-F]+$'; then
    echo "$(date) - IP 地址格式错误: $ip_address" >> "$log_file"
    exit 1
  fi
}


# 获取当前 IPv4 地址
current_ipv4=$(curl -4 ip.sb)
if [ $? -ne 0 ]; then
  echo "$(date) - 获取 IPv4 地址失败" >> "$log_file"
  exit 1
fi
check_ip "$current_ipv4"

# 获取当前 IPv6 地址
current_ipv6=$(curl -6 ip.sb)
if [ $? -ne 0 ]; then
  echo "$(date) - 获取 IPv6 地址失败" >> "$log_file"
  exit 1
fi
check_ip "$current_ipv6"

# 获取域名解析到的 IPv4 地址
resolved_ipv4=$(dig +short A $hostname)
check_ip $resolved_ipv4

# 获取域名解析到的 IPv6 地址
resolved_ipv6=$(dig +short AAAA $hostname)
check_ip $resolved_ipv6

# 定义更新函数
update_ip() {
  local ip_address=$1
  local update_result=$(curl -s -u "$username:$password" "https://dynupdate.no-ip.com/nic/update?hostname=$hostname&myip=$ip_address")
  if echo "$update_result" | grep -q "good"; then
    echo "$(date) - IP 地址 $ip_address 已更新" >> "$log_file"
  elif echo "$update_result" | grep -q "nochg"; then
    echo "$(date) - IP 地址 $ip_address 无需更新" >> "$log_file"
  else
    echo "$(date) - 更新失败: $update_result - IP: $ip_address" >> "$log_file"
  fi
}

echo "$(date) -  当前 $current_ipv4, $current_ipv6 ,域名ip:$resolved_ipv4,$resolved_ipv6  开始检查...">> "$log_file"
# 检查 IPv4 地址是否改变
#if [ "$current_ipv4" != "$resolved_ipv4" ]; then
#  update_ip "$current_ipv4"
#fi

# 检查 IPv6 地址是否改变
#if [ "$current_ipv6" != "$resolved_ipv6" ]; then
#  update_ip "$current_ipv6"
#fi
# 如果 IPv4 和 IPv6 地址改变了，则同时更新
if [ "$current_ipv4" != "$resolved_ipv4" ] || [ "$current_ipv6" != "$resolved_ipv6" ]; then
  update_ip "$current_ipv4,$current_ipv6"
fi
# 检查日志文件行数
log_file_lines=$(wc -l "$log_file" | awk '{print $1}')

# 如果行数超过 10000，则裁剪到 1000 行
if [ "$log_file_lines" -gt 10000 ]; then
  tail -n 1000 "$log_file" > "$log_file.tmp"
  mv "$log_file.tmp" "$log_file"
fi
