## 练习1：
### 代码分析
我们首先对first fit算法进行分析，重点分析其中的函数，以便了解页面分配算法的实现方法，为后续的实验打好基础。

default_init：初始化空闲内存块链表，空闲页面总数清零。

default_init_memmap：初始化内存映射，初始化每个页面的属性，设置空闲块首页属性，按物理地址顺序插入空闲列表。我们可以重点关注下面这一段代码：
```c
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
```
if部分是面对空表时，直接把base对应的页插入到空闲链表中；else部分中有一个while循环，循环条件很巧妙，利用了双向链表的结构，最后一个节点的next指针会指向开头，既完成了节点指针向后移动，又完成了遍历结束的判断。之后就是对base进行地址的比较，按大小排好了顺序。

default_alloc_pages：分配物理页面，进行first-fit搜索，找到第一个足够大的块，将其从列表里移除后，再判断这个块的空间是否大于申请空间，超出的部分还要插回列表，由于记录了prev节点，已经保证了地址顺序，所以不需要再寻找插入位置。在这个过程中需要注意property属性的更新，最后还要把分配的页面属性清空，表示不再是空闲的页面。

default_free_pages：释放物理页面，按照地址顺序插入空闲链表后，分别向前向后合并空闲块，要注意被合并的后面那一个块的状态也要更新，首先清除property标签，并从链表上删除。

系统启动时先调用default_init()进行初始化，然后对可用的物理内存区域调用default_init_memmap()，建立初始空闲块。分配内存时调用default_alloc_pages分配，然后调用default_free_pages释放从base开始的n个页面，并检查合并前后相邻块。
### 优化思路
first-fit优化：考虑优化查找效率，线性扫描时间复杂度为O(n)，可以考虑改变数据结构实现更高效率查找，或者采用二分查找等更高效的查找算法。考虑优化内存管理，利用伙伴系统将内存按2的幂次方划分。