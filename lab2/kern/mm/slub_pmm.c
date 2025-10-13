#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <slub_pmm.h>
#include <stdio.h>

typedef struct slab {
    struct Page *page;       // 该 slab 对应的页
    void *free_list;         // 指向第一个空闲对象
    size_t free_count;       // 空闲对象数
    struct slab *next;       // 指向下一个 slab
} slab_t;
typedef struct kmem_cache {
    size_t obj_size;         // 对象大小
    slab_t *slab_list;       // 指向第一个 slab
    struct kmem_cache *next; // 指向下一个缓存
} kmem_cache_t;
#define SIZES_NUM 5
static kmem_cache_t cache_list[SIZES_NUM];
static size_t cache_sizes[SIZES_NUM] = {32, 64, 128, 256, 512};

static void
slub_init(void) {
    buddy_manager.init();
    for (int i = 0; i < SIZES_NUM; i++) {
        cache_list[i].obj_size = cache_sizes[i];
        cache_list[i].slab_list = NULL;
        cache_list[i].next = (i + 1 < SIZES_NUM) ? &cache_list[i + 1] : NULL;
    }

    cprintf("SLUB initialized with caches for sizes: ");
    for (int i = 0; i < SIZES_NUM; i++) {
        cprintf("%d ", cache_sizes[i]);
    }
    cprintf("\n");
}

static void
slub_init_memmap(struct Page *base, size_t n) {
      buddy_manager.init_memmap(base, n);
}
// 查找合适的 cache（按对象大小）
static kmem_cache_t *find_cache(size_t size) {
    for (int i = 0; i < SIZES_NUM; i++) {
        if (size <= cache_list[i].obj_size)
            return &cache_list[i];
    }
    return NULL;
}

// 创建一个新的 slab（从 buddy 分配 1 页）
static slab_t *slab_create(kmem_cache_t *cache) {
    struct Page *page = buddy_manager.alloc_pages(1);
    if (!page) return NULL;

    slab_t *slab = (slab_t *)page;
    slab->page = page;
    slab->free_count = PGSIZE / cache->obj_size;
    slab->next = cache->slab_list;
    cache->slab_list = slab;

    // 构建空闲链表
    uintptr_t base = (uintptr_t)(slab + 1);
    void **prev = NULL;
    for (size_t i = 0; i < slab->free_count; i++) {
        void *obj = (void *)(base + i * cache->obj_size);
        if (prev) *prev = obj;
        prev = (void **)obj;
    }
    if (prev) *prev = NULL;
    slab->free_list = (void *)(slab + 1);

    return slab;
}


static struct Page *
slub_alloc_pages(size_t n) {
   if (n == 0) return NULL;

    // 找到合适 cache
    kmem_cache_t *cache = find_cache(n);
    if (!cache) {
        // 太大，直接从 buddy 分配
        return buddy_manager.alloc_pages((n + PGSIZE - 1) / PGSIZE);
    }

    // 找到可用 slab
    slab_t *slab = cache->slab_list;
    while (slab && slab->free_count == 0) {
        slab = slab->next;
    }

    if (!slab) {
        slab = slab_create(cache);
        if (!slab) return NULL;
    }

    void *obj = slab->free_list;
    slab->free_list = *(void **)obj;
    slab->free_count--;

    return slab->page;
}

static void
slub_free_pages(struct Page *base, size_t n) {
    
}

static size_t
slub_nr_free_pages(void) {
    return buddy_manager.nr_free_pages();
}

static void
slub_check(void) {

}



const struct pmm_manager slub_manager = {
    .name = "slub_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};

