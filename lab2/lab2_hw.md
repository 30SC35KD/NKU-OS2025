练习1：

default_init：初始化空闲内存块链表，空闲页面总数清零。

default_init_memmap：初始化内存映射，初始化每个页面的属性，设置空闲块首页属性，按物理地址顺序插入空闲列表。

default_alloc_pages：分配物理页面，进行first-fit搜索，找到第一个足够大的块，将其从列表里移除后，再把剩余部分插回列表。

default_free_pages：释放物理页面，分别向前向后合并空闲块。

系统启动时先调用default_init()进行初始化，然后对可用的物理内存区域调用default_init_memmap()，建立初始空闲块。分配内存时调用default_alloc_pages分配，然后调用default_free_pages释放从base开始的n个页面，并检查合并前后相邻块。

first-fit优化：考虑优化查找效率，线性扫描时间复杂度为O(n)，可以考虑改变数据结构实现更高效率查找。考虑优化内存管理，利用伙伴系统将内存按2的幂次方划分。