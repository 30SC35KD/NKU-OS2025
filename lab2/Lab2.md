## 练习2
我们需要在`best_fit_pmm.c`中进行代码修改：
### 初始化页框
```c
p ->flags = 0;
p ->property = 0;
set_page_ref(p, 0);
```
我们通过如上代码清空当前页框的标志和属性信息（块数），调用函数将页框的引用计数设置为0，这一部分与first-fit的做法保持一致。
```c
if (base < page) {
    list_add_before(le, &(base->page_link));
    break;
} else if (list_next(le) == &free_list) {
    list_add(le, &(base->page_link));
}
```
这部分出现在对free_list的循环中，即为该页面寻找一个插入链表的位置，这个位置恰在循环中第一个大于该页面地址的页面之前，如果该页面地址最大，就插在链表结尾。这一部分仍与first-fit的做法保持一致
### Best-Fit
```c
while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            if(p->property < min_size) {
                page = p;
                min_size = p->property;
            }
        }
    }
```
接下来我们在分配页面的函数中实现best-fit的核心代码，与first-fit不同的是，如果页面大小大于请求的大小，并不是直接将其设置为最终分配的页面并退出循环，而是再加入一个判断，如果其为当前最小的符合要求的页面，那设置为暂时分配的页面并且不退出循环，直到free_list遍历完，当前最小的符合要求的页面才是最终分配的页面。在这其中我们设置了min_size变量，作为“最小”的标准，初始值为总空闲页块数+1，保证一定可以被更新。
### 释放页面
```c
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
```
这一部分仍然与first_fit保持一致，即设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值。
```c
if(p+p->property == base) {
        p->property += base->property;
        ClearPageProperty(base);
        list_del(&(base->page_link));
        base = p;
    }
```
这一部分是实现连续空闲页块，前一个page的地址加上页块大小如果恰好等于该页面地址，那么就说明可以合并，首先是大小向家，然后清除被合并页块的属性标记，也就是不再为空闲，然后从链表里删除该页块，最后把地址更新为前一个空闲页块。
至此我们完成了best-fit的核心代码编写，下面我们在**pmm.c**的代码中修改一行代码：

**pmm_manager = &best_fit_pmm_manager;**

把best-fit方法的指针给pmm_manager，因为两者内存布局相同，所以pmm_manager调用函数时实际上调用的是best-fit的相关方法。
使用**make grade**命令进行测试，结果如下：
![alt text](figs/image1.png)
我们通过了best-fit的所有测试，说明编写成功！