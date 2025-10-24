#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

static buddy_free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)
static void
buddy_init(void) {
    for(int i=0;i<MAX_ORDER;i++){
        list_init(&free_list[i]);
        nr_free[i]=0;
    }
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    cprintf("buddy_init_memmap: base %p, n %lu\n", base, n);
    assert(n > 0);

    struct Page *p = base;
    size_t idx = p - pages;  // 当前页号
    cprintf("Starting idx: %d\n", idx);
    size_t left = n;

    while (left > 0) {
        int order = MAX_ORDER - 1;
        while ((1U << order) > left)
            order--;
        while (idx & ((1U << order) - 1))
            order--;

        p->flags = 0;
        p->property = 1U << order;
        set_page_ref(p, 0);
        SetPageProperty(p);
        list_add_before(&free_list[order], &(p->page_link));
        nr_free[order]++;

        p += (1U << order);
        idx += (1U << order);
        left -= (1U << order);
    }
}

static int get_order(size_t n) {
    int order = 0;
    size_t size = 1;
    while (size < n) {
        size <<= 1;
        order++;
    }
    return order;
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    int order = get_order(n);
    int alloc_order = get_order(n);
    while(order<MAX_ORDER && list_empty(&free_list[order])){
        order++;
    }
    if(order==MAX_ORDER) return NULL; // 没有合适的块

    struct Page *p = le2page(list_next(&free_list[order]), page_link);
    list_del(&(p->page_link));
    nr_free[order]--;

    
    while(order >alloc_order)
    {
        order--;
        struct Page *buddy = p + (1U << order);
        buddy->property = 1U << order;
        SetPageProperty(buddy);
        list_add(&free_list[order], &(buddy->page_link));
        nr_free[order]++;
        p->property = 1U << order;
        SetPageProperty(p);
    }
    ClearPageProperty(p);
    return p;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    int order = get_order(n);
    struct Page *page = base;
    
    // 递归合并 buddy 块
    while (order < MAX_ORDER-1) {
        size_t block_size = 1U << order;
        size_t idx = page - pages;
        size_t buddy_idx = idx ^ block_size; 
        struct Page *buddy = &pages[buddy_idx];
//cprintf("Checking buddy at idx %d: is_free=%d, property=%d, expected_size=%d\n",buddy_idx, PageProperty(buddy), buddy->property, block_size);
        // 检查 buddy 是否空闲且同阶
        if (!(PageProperty(buddy) && buddy->property == block_size)) {
            //cprintf("Merge failed for page at idx %d with buddy %d\n", idx, buddy_idx);
            break; // 不能合并，跳出循环
        }
        list_del(&(buddy->page_link));
        nr_free[order]--;
        if (buddy < page) {
            page = buddy;
        }
        order++; 
    }

    page->property = 1U << order;
    SetPageProperty(page);
    set_page_ref(page, 0);
    list_entry_t *le = &free_list[order];
    list_add(le, &(page->page_link));
    nr_free[order]++;
}

static size_t
buddy_nr_free_pages(void) {
    size_t total = 0;
    for (int order = 0; order < MAX_ORDER; order++) {
        total += nr_free[order] * (1U << order);
    }
    return total;
}

static void
buddy_check(void) {
    int free_cnt = 0;

    int count = 0;
    size_t total = 0;
    for (int order = 0; order < MAX_ORDER; order++) {
        list_entry_t *le = &free_list[order];
        size_t block_size = 1U << order;
        while ((le = list_next(le)) != &free_list[order]) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p));
            assert(p->property == block_size);
            assert(((p - pages) & (block_size - 1)) == 0); 
            count++;
            total += block_size;
        }
    }
    assert(total == buddy_nr_free_pages());

    struct Page *p0, *p1, *p2;
    
    p0 = p1 = p2 = NULL;
    
    p0 = buddy_alloc_pages(1);
    p1 = buddy_alloc_pages(1);
    assert(p0 != NULL && p1 != NULL);
    assert(list_empty(&free_list[0]) && list_empty(&free_list[1]));
    p2 = buddy_alloc_pages(1);
    assert(nr_free[0] == 1 && nr_free[1] == 1 && nr_free[2] == 1 && nr_free[3] == 0);
    struct Page *p3 = buddy_alloc_pages(512);
    assert(nr_free[9] == 1);
    struct Page *p4 = buddy_alloc_pages(512);
    assert(p3 != NULL && p4 != NULL);
    struct Page *p5 = buddy_alloc_pages(1024);
    assert(nr_free[10]==29);
    struct Page *p6 = buddy_alloc_pages(100);
    assert(list_empty(&free_list[7])&&list_empty(&free_list[6])&&list_empty(&free_list[8])&&list_empty(&free_list[9]));
    struct Page *p7 = buddy_alloc_pages(62);
    assert(p6 != NULL && p7 != NULL);
    struct Page *p8 = buddy_alloc_pages(2048);
    assert(p8 == NULL);
  
    buddy_free_pages(p0, 1);
    buddy_free_pages(p1, 1);
    assert(nr_free[1] == 2);
    buddy_free_pages(p2, 1);
    assert(nr_free[1] == 1 && nr_free[2] == 0 && nr_free[3] == 1);
    buddy_free_pages(p3, 512);
    buddy_free_pages(p4, 512);
    assert(nr_free[10] == 29);
    buddy_free_pages(p5, 1024);
    buddy_free_pages(p6, 128);
    buddy_free_pages(p7, 64);
    assert(nr_free[6] == 0 && nr_free[8] == 0 && nr_free[9] == 0);
    assert(buddy_nr_free_pages() == total);
    
//  for (int i = 0; i < MAX_ORDER; i++) {
//         free_cnt += nr_free[i] * (1U << i);
//         cprintf("%d \n",nr_free[i]);
//     }
    
}



const struct pmm_manager buddy_manager = {
    .name = "buddy_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};

