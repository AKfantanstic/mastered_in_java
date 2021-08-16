## ArrayList

底层使用数组实现，初始容量10，而数组的长度是固定的，不能频繁的往ArrayList中塞数据，导致它频繁进行数组扩容，避免扩容时较差的性能影响了系统的运行



优点：基于数组实现十分适合随机读，并且性能较高

缺点: 基于数组实现，如果往数组中间加元素，会导致大量的元素挪一个位置，开销很大

### add()方法的源码

```java
/**
将指定元素附加到此列表的末尾
*/
public boolean add(E e) {
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        elementData[size++] = e;
        return true;
    }
```

### set()方法源码

```java
/**
用指定元素替换列表中指定位置的元素
*/
public E set(int index, E element) {
        rangeCheck(index);

        E oldValue = elementData(index);
        elementData[index] = element;
        return oldValue;
    }
```



### add(index,element)方法的源码





### get()方法的源码





### remove()方法的源码





### 扩容

ArrayList中最关键的逻辑就是如果数组填充满了后，如何进行扩容。







底层基于数组，最大的问题就是不要频繁的往里面灌入大量数据，导致频繁的数组扩容，新老数组元素拷贝，中间位置插入元素，删除元素，都会导致大量的元素移动，随机获取一个元素，get(index)操作是性能极高的，适合随机读，不适合大量频繁的写入及插入

### 源码分析总结

* remove()、add（index，element），这两个方法都会导致数组的拷贝，大量元素的挪动，基于数组做这种随机位置的插入和删除，性能真的不是太高

* add()、add(index,element),这两个方法，都可能会导致数组需要扩容，而数组的长度是固定的，要想扩容就只能重新开辟一个更大的数组，然后把原来数组中的元素全部拷贝到新数组中。默认初始大小是10个元素，如果不停往数组里塞入数据，可能会导致瞬间数组不停的扩容，影响系统的性能

* set(),get()，定位到随机的位置去替换元素，或者是获取元素，由于是基于数组来实现随机位置的定位，性能还是很高的