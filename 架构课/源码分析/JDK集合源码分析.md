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

## LinkedList

底层基于双向链表实现。其他所有特性都是围绕着底层用双向链表来实现的所展开的，

优点：不停往linkedList里插入元素，或者往中间插入元素，都没关系，因为链表不需要像数组那样挪动大量元素，直接在链表中加节点即可，也不用考虑扩容对性能的影响。所以使用场景非常适合频繁插入

缺点：由于底层是链表，所以不太适合随机位置读取，因为需要遍历链表。而ArrayList这种底层是数组的实现就不需要遍历，直接根据内存地址，和所指定的index，直接定位到那个元素

LinkedList和ArrayList的区别，就是数组和链表的区别

使用场景：

(1)ArrayList：一般场景都是用ArrayList代表一个集合，只要不会频繁插入或者灌入大量元素导致频繁扩容后数组频繁拷贝，用来遍历或者随机查都是可以的

(2)LinkedList: 适合频繁在list中插入和删除某个元素。LinkedList可以当作队列来用

如何回答ArrayList和LinkedList的区别是什么？

答：ArrayList的源码我看过，给你讲一下，add，remove，get，set方法的一些基于数组实现的原理是什么，数组扩容，元素移动的原理是什么，优缺点是什么

LinkedList是基于双向链表实现的，可以现场画一下他的数据结构，把他的一些常见操作原理图现场画一下，指针，双向链表的数据结构，node是怎么变化的



在队列头加一个元素，获取一个元素，删除一个元素，在队列尾部加一个元素，获取一个元素，删除一个元素，在队列中间插入一个元素获取一个元素，删除一个元素

### 插入元素

add()： 默认是在双向链表的尾部插入一个元素

add(index,element): 是在队列的中间插入一个元素

addFirst()： 在队列头部插入一个元素

addLast(): 跟add方法是一样的，也是在尾部插入一个元素



对于add(index,element)的思路，是先确定index位置在前半部分还是后半部分，如果是前半部分则从头节点遍历，如果是后半部分则从尾节点遍历，找到index位置的node，然后替换元素即可。具体源码实现:

size>>1,右移一位，相当于是size/2,如果index<(size>>1)则说明要插入的位置在队列的前半部分，就会从队列头开始遍历直到找到index那个位置的node

```java
 if (index < (size >> 1)) {
            Node<E> x = first;
            for (int i = 0; i < index; i++)
                x = x.next;
            return x;
        } else {
// 如果index >= size / 2，说明要找的节点是在队列的后半部分
// 此时就是从队列的尾部往前遍历
            Node<E> x = last;
            for (int i = size - 1; i > index; i--)
                x = x.prev;
            return x;
        }
```







### 获取头部元素

getFirst()== peek(),其实是直接返回first指针指向的那个node。这两个方法的区别：getFirst()如果是对空list调用，会抛异常；而peek()对空list调用，会返回null

### 获取尾部元素

### 获取某个位置的元素

```java
public E get(int index) {
        checkElementIndex(index);
        return node(index).item;
}
```

这个操作是ArrayList的强项，通过数组的index就可以定位元素，性能超高。

而对于LinkedList来说，get(int index)是它的弱项。如果想要获取某个随机位置的元素， 需要使用node(index)这个方法，而这个方法需要进行链表的遍历，只不过会用index和size>>1进行比较下，如果在前半部分则从头部开始遍历；如果在后半部分则从尾部开始遍历

### 删除元素

removeLast()

removeFirst() == poll()

remove(int index)





冒泡，快排，二分查找，理论上来说，一般的算法都可以通过画图来理解。包括红黑树，treeMap，hashMap底层现在也有红黑树了，都是画图，输入一些参数并通过代码运行，图不断变动，理解这个数据结构和算法的原理

## Vector和Stack

栈，有vector和stack两个实现。stack代表了一个栈这种数据结构，它是继承自vector来实现的，而vector是一种类似于ArrayList(基于数组来实现的)数据结构，也是基于数组来实现的



栈的特点是先进后出

### 压栈

push()方法，几乎和ArrayList的add()方法实现的源码是一样的，就是把元素放在数组按顺序排列的位置上

```java
public synchronized void addElement(E obj) {
        modCount++;
        ensureCapacityHelper(elementCount + 1);
        elementData[elementCount++] = obj;
}
```

ArrayList每次扩容是1.5倍 capacity + (capacity >> 1)=1.5 capacity

Vector每次扩容默认是2倍，默认情况下直接扩容2倍







linkedList可以当作队列使用：

offer() == add()，在队列尾部入队

poll()，从队列头部出队

peek()，获取队列头部的元素但不出队



















