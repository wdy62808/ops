#!/bin/bash
# author : dywang
pkg_py3="/opt/Python-3.6.8.tgz"
install_py3_dir="/usr/local/python3"
echo "安装python3 依赖"
yum install zlib-devel bzip2-devel openssl-devel ncurses-devel gcc -y >>/dev/null && echo "安装python 3 依赖 Succ" || (echo "安装python3依赖 Error " && exit 1) 
test -e ${pkg_py3} >>/dev/null || (echo "Python-3.6.8.tgz 文件不存在" && exit 1)
echo "解压Python3.6文件"
cd /opt
wget https://www.python.org/ftp/python/3.6.8/Python-3.6.8.tgz
tar xzvf ${pkg_py3} -C /opt/ >>/dev/null && echo "解压python3文件 Succ" || (echo "解压python3文件 Error" && exit 1)
echo "编译安装python3"
cd /opt/Python-3.6.8 || echo "/opt/Python-3.6.8目录不存在"
./configure --prefix=${install_py3_dir} >>/dev/null && echo "configure python3 Succ" || (echo "configure python3 finished Error" && exit 1)
make -j$(nproc) >>/dev/null && echo "编译python3 Succ"|| echo "编译 python3 Error"
make install >>/dev/null && echo "安装python3 Succ" || echo "安装 python3 Error"

[ -f /usr/local/bin/python3 ] && mv /usr/local/bin/python3 /usr/local/bin/python3_old
[ -f /usr/local/bin/pip3 ] && mv /usr/local/bin/pip3  /usr/local/bin/pip3_old
echo "创建软连接"
ln -s /usr/local/python3/bin/python3.6 /usr/local/bin/python3 && echo "创建python3软连接 Succ" || echo "创建python3软连接 Error" 
ln -s /usr/local/python3/bin/pip3 /usr/local/bin/pip3 && echo "创建pip3软连接 Succ" || echo "创建ppip3软连接 Error" 

echo "检测python3、pip3"
echo "Python3 version: "`python3 -V`  2>>/dev/null||(echo "安装失败没有python3 命令" && exit 1)
echo "pip3 version: "`pip3 -V` 2>>/dev/null||(echo "安装失败没有pip3 命令" && exit 1)

echo "升级pip3"
pip3 install --upgrade pip >>/dev/null && echo "pip3 升级 Succ" || (echo "pip3 升级 Error"  && exit 1)
if [ $? -ne 0 ];then
    echo "重新尝试升级pip3"
    pip3 install --trusted-host pypi.org --trusted-host files.pythonhosted.org --upgrade pip && echo "pip3 升级 Succ" || (echo "pip3 升级 Error" && exit 1)
fi 
echo "pip3 version: "`pip3 -V` 2>>/dev/null||echo "安装失败没有pip3 命令"

echo "安装ipython3"
pip3 install ipython >>/dev/null && echo "安装ipython3 Succ" || (echo "安装 ipython3 Error"  && exit 1)
if [ $? -ne 0 ];then
    echo "重新尝试安装ipython3"
    pip3 install  --trusted-host pypi.org --trusted-host files.pythonhosted.org ipython
fi
ln -s /usr/local/python3/bin/ipython /usr/bin/ipython3 && echo "创建ipython3 软连接 Succ" || echo "创建 ipython3软连接 Error" 
echo "ipython3 version: "`ipython3 -V` 2>>/dev/null|| echo "安装失败没有ipyhton3 命令"

echo "创建py3虚环境"
python3 -m venv /opt/py3 && echo "虚环境 /opt/py3 创建 Succ" || echo "虚环境 /opt/py3 创建 Error" 
#echo "激活虚环境"
#source /opt/py3/bin/activate 
#退出 虚环境  deactivate

echo "删除安装文件"
rm -rf /opt/Python-3.6*