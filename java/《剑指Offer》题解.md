剑指offer题解:

### 问题1: 单例模式
(1)双重检查锁:  
```
public class Singleton {

    private volatile static Singleton singleton;

    // 私有化构造方法，防止随意创建对象
    private Singleton(){}

    public static Singleton getInstance(){
        // 先判断对象是否已经实例化，没有实例化则加锁
        if (singleton == null){
            // 同步代码块方式加锁
            synchronized (Singleton.class){
                if (singleton==null){
                    singleton = new Singleton();
                }
            }
        }
        return singleton;
    }
}
```
关键字: volatile  

拓展:用 volatile 修饰的原因: singleton = new Singleton(),这句话分为3步，  
        memory = allocate()  1.在内存中为对象分配一块空间  
        ctorInstance(memory) 2. 初始化对象(我理解为实例化对象)  
        instance = memory    3.将instance指向分配的内存地址  
在编译器中 2和3是可以被重排序的，用volatile来禁止指令重排序(当声明对象的引用为volatile后，2和3的重排序在多线程环境中将被禁止),volatile 还有一个作用是保持可见性   

### 问题3:  
解法1: 先排序，然后遍历，如果当前值和下一个值相同，则输出  
解法2: 开O(n)空间的map或者set，然后遍历，遍历判断。set在添加相同元素时会返回一个false  
解法3: 思路:首先需要遍历数组，如果当前遍历的下标和当前数字不相等，说明需要交换了，交换之前有个前提，
那就是先判断一下当前数字和数组下标为当前数字的数字是否相等，如果相等，那我们就直接找到了一个重复的数字
```
    /**
     * 思路:首先需要遍历数组，如果当前遍历的下标和当前数字不相等，说明需要交换了，交换之前有个前提，
     * 那就是先判断一下当前数字和数组下标为当前数字的数字是否相等，如果相等，那我们就直接找到了一个重复的数字
     *
     * @param nums
     * @return
     */
    public static int findRepeatNumber(int[] nums) {
        for(int i = 0; i < nums.length; i++) {
            while(nums[i] != i) {
                if(nums[i] == nums[nums[i]]) return nums[i];
                swap(nums, i, nums[i]);
            }
        }
        return -1;
    }

public static void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
```

### 问题4:
```
   /**
     * 从右上角开始找，比较target和右上角值的大小，target大就去掉
     * @param matrix
     * @param target
     * @return
     */
    public static boolean findNum(int[][] matrix, int target) {
        boolean isFind = false;

        int rows = matrix.length; // 行数
        if (rows == 0) {// 输入空的二维数组直接返回false
            return false;
        }
        int columns = matrix[0].length; // 列数

        int column = columns - 1; //这里定义右上角的坐标值，也是遍历的开始点
        int row = 0;
        while (column >= 0 && row <= rows - 1) {
            if (matrix[row][column] == target) {
                isFind = true;
                break;
            } else if (target > matrix[row][column]) {// 当前数字比目标小，去掉一行
                row++;
            } else {
                // 当前数字比目标大，去掉一列
                column--;
            }
        }
        return isFind;
    }
```

```
 /**
     * 从左下角找
     *
     * @param matrix
     * @param target
     * @return
     */
    public static boolean findNumTwo(int[][] matrix, int target) {
        int rows = matrix.length;
        boolean isFind = false;

        if (rows == 0) {
            return isFind;
        }

        int columns = matrix[0].length;

        int row = rows - 1;
        int column = 0;

        while (column <= columns-1 && row >= 0) {

            if (target==matrix[row][column]){
                isFind = true;
                break;
            }else if (target>matrix[row][column]){
                column++;
            }else{
                row--;
            }
        }
        return isFind;
    }
```

### 问题6:

```
public class Problem6 {

    private List<Integer> list = new ArrayList<>();

    static class ListNode {
        int val;
        ListNode next;

        ListNode(int x) {
            val = x;
        }
    }

    /**
     * 用栈辅助解决
     *
     * @param head
     * @return
     */
    public int[] reversePrint(ListNode head) {

        if (head == null) {
            return new int[]{};
        }
        java.util.Stack<Integer> stack = new Stack<>();
        while (head != null) {
            stack.push(head.val);
            head = head.next;
        }
        int size = stack.size();
        int[] arr = new int[size];
        for (int i = 0; i < size; i++) {
            arr[i] = stack.pop();
        }
        return arr;
    }

    /**
     * 用递归解决
     *
     * @return
     */
    public int[] reversePrintTwo(ListNode head) {
        reverseCurrent(head);
        int[] arr = new int[list.size()];
        for (int i = 0; i < list.size(); i++) {
            arr[i] = list.get(i);
        }
        return arr;
    }

    // 将节点值以递归按倒序放入list
    // 因为递归相当于函数调用函数，函数调用函数，...，直到触发终止条件。
    // 回溯（即返回时），前面的那些函数才算“执行完毕”，才可以执行下面的 list.add(head.val)  
    void reverseCurrent(ListNode head) {
        if (head == null) {
            return;
        }
        reverseCurrent(head.next);
        list.add(head.val);
    }
}
```

### 问题9:
```
public class CQueue {

    private Stack<Integer> inStack;

    private Stack<Integer> outStack;

    public CQueue() {
        inStack = new Stack<>();
        outStack = new Stack<>();
    }

    public void appendTail(int value) {
        inStack.push(value);
    }

    public int deleteHead() {
        // 两个栈都为空，说明队列内无元素
        if (inStack.isEmpty() && outStack.isEmpty()) {
            return -1;
        }
        if (outStack.isEmpty()) {
            // outStack为空时，将inStack中所有元素都压入outStack中。
            while (!inStack.isEmpty()){
                outStack.push(inStack.pop());
            }
        }
        return outStack.pop();
    }
}
```

### 问题10: 
```
public class Problem10 {
    public static void main(String[] args) {
        System.out.println(fibonacci(45));
        System.out.println(fibonacci2(45));
        System.out.println(fibonacci3(1));
    }

    /**
     * 用递归的方式去分析问题，然后用循环来解决问题。并且从下往上算，避免计算重复的子问题
     *
     * @param n
     * @return
     */
    public static long fibonacci2(int n) {
        int[] result = new int[]{0, 1};
        if (n < 2) {
            return result[n];
        }
        int fibonacciN = 0;
        int fibonacciOne = 1;

        int fibonacciTwo = 0;

        for (int i = 2; i <= n; ++i) {
            fibonacciN = (fibonacciOne + fibonacciTwo) % 1000000007;
            fibonacciTwo = fibonacciOne;
            fibonacciOne = fibonacciN;
        }
        return fibonacciN;
    }

    /**
     * a,b,sum 来保存3项的结果
     * @param n
     * @return
     */
    public static int fibonacci3(int n) {
        int a = 0, b = 1, sum;
        for (int i = 0; i < n; i++) {
            sum = (a + b) % 1000000007;
            a = b;
            b = sum;
        }
        return a;
    }


    // 纯递归方式，这种方式的缺点是子问题被重复计算
    public static long fibonacci(long n) {
        if (n <= 0) {
            return 0;
        }
        if (n == 1) {
            return n;
        }
        return (fibonacci(n - 1) + fibonacci(n - 2)) % 1000000007;

    }
}
```

### 青蛙跳台阶:  
当青蛙要跳n级台阶时，把这个过程看成一个函数 --> f(n)。当n>2时，第一次可以选跳一级，剩下的次数为f(n-1),
如果第一次选择跳2级，剩下的次数为f(n-2),得出f(n) = f(n-1)+ f(n-2),此为斐波那契数列。  

### 变态跳台阶:  
方法1: 跳n级台阶，前n-1级台阶，每个台阶都有两种选择，跳或者不跳，第n级台阶是必跳的，这级不用选择，
所以结果是2的n-1次方 
方法2: 跳n级台阶，第一步如果跳1级，那跳法有f(n-1)种;第二步如果跳2级，跳法有f(n-2)种，
所以f(n) = f(n-1)+f(n-2)+...+f(1)
f(n-1) = f(n-2)+...+f(1)
得到 上式减去下式得到: f(n) -f(n-1) = f(n-1) --> f(n) = 2 * f(n-1)  

### 问题12: 
请设计一个函数，用来判断在一个矩阵中是否存在一条包含某字符串所有字符的路径。路径可以从矩阵中的任意一格开始，每一步可以在矩阵中向左、右、上、下移动一格。
如果一条路径经过了矩阵的某一格，那么该路径不能再次进入该格子。  

思路:
1. 将目标字符串转为字符数组，方便一个个匹配  
2. 两个for循环对矩阵每个点进行扫描  
3. 从第一个点开始递归遍历  
4. （进入DFS）判断是否越界以及匹配，递归到字符数组最后一个字符，说明完成完整的匹配 返回true  
5. 将当前遍历的点存入tmp中暂存  
6. 修改当前点的字符，标记其为被访问过  
7. （递归开始）对其四个方向的点搜索是否满足匹配  
8. 递归完成后，回溯，将修改过的点还原  
9. 返回结果  
```
public class Problem12 {
    public static void main(String[] args) {
        char[][] board = new char[][]{{'A','B','C','E'},{'S','F','C','S'},{'A','D','E','E'}};
        String word = "ABCCED";
        System.out.println(exist(board,word));
    }

    public static boolean exist(char[][] board,String word){
        char[] words = word.toCharArray();
        for (int row=0;row<board.length;row++){
            for (int col = 0;col<board[0].length;col++){
                if (dfs(board,words,row,col,0)){
                    return true;
                }
            }
        }
        return false;
    }

    public static boolean dfs(char[][] board,char[] words,int row,int col,int k){
        // 如果row 或 col越界，或者当前矩阵中字符和 第k个字符不匹配，返回false
        if (row>=board.length||row<0||col>=board[0].length||col<0|| board[row][col]!=words[k]){
            return false;
        }
        if (k==words.length-1){
            return true;
        }
        char tmp = board[row][col];
        board[row][col] = '/';
        boolean res =
                dfs(board,words,row+1,col,k+1)|| dfs(board,words,row-1,col,k+1) ||
                        dfs(board,words,row,col+1,k+1)|| dfs(board,words,row,col-1,k+1);
        board[row][col] = tmp;
        return res;
    }
}
```

### 问题13:  
地上有一个m行n列的方格，从坐标 [0,0] 到坐标 [m-1,n-1] 。一个机器人从坐标 [0, 0] 
的格子开始移动，它每次可以向左、右、上、下移动一格（不能移动到方格外），也不能进入行坐标和列坐标的数位之和大于k的格子。例如，当k为18时，机器人能够进入方格 [35, 37] ，因为3+5+3+7=18。但它不能进入方格 [35, 
38]，因为3+5+3+8=19。请问该机器人能够到达多少个格子？  

```
public class Problem13 {

    private int m,n,k,res;

    private boolean[][]mark;

    public static void main(String[] args) {

    }

    public int movingCount(int m,int n,int k){
        this.m = m;
        this.n = n;
        this.k = k;
        this.res = 0;
        // m * n的矩阵，k为限制的数位和
        mark = new boolean[m][n];
        dfs(m,n,0,0);
        return res;
    }

    public void dfs(int m,int n,int row,int col){
        // 访问越界 或者 数位和大于k 或者已经访问过，返回
        if (row>m-1||col>n-1||!getSumNum(row,col,k)||mark[row][col]){
            return;
        }
        mark[row][col] = true; //标记已访问过
        res++; // 有效位置+1
        dfs(m,n,row+1,col); //向右递归
        dfs(m,n,row,col+1); //向下递归
    }

    public boolean getSumNum(int row,int col,int k){

        int sum = 0;
        while(row!=0){
            sum +=row%10;
            row/=10;
        }
        while(col!=0){
            sum +=col%10;
            col /=10;
        }
        if (sum>k){
            return false;
        }
        return true;
    }
}

```

### 问题14: 
给你一根长度为 n 的绳子，请把绳子剪成整数长度的 m 段（m、n都是整数，n>1并且m>1），每段绳子的长度记为 k[0],k[1]...k[m] 。请问 k[0]*k[1]*...*k[m] 
可能的最大乘积是多少？例如，当绳子的长度是8时，我们把它剪成长度分别为2、3、3的三段，此时得到的最大乘积是18。  

思路:  
(1)暴力递归，列举所有可能的乘积，找出最大的一个  
(2)动态规划，遍历求解长度为i的绳子的最大乘积，当遍历到长度为i的绳子时，求出所有可能的乘积，找出最大的一个，则就得到了长度为i的绳子的最大长度。  
(3)贪心。贪心的前提是需要证明每一步贪心的局部最优解，可以得到全局的最优解。想用贪心，先证明，然后再用贪心算法写代码。  

贪心证明过程: 
n=2时，max =1x1 = 1; 
n=3时，max=2x1 = 2 ; 
n=4，max=2x2 = 4;
n=5,max =3x2 =6;
n=6,max =3x3 = 9;
n=7,max = 3x2x2 = 12; 这里不选 3x3x1 = 9,因为3x2x2=12 > 3x3x1=9 
n=8,max = 3x3x2= 18;
n=9,max = 3x3x3 = 27;
n=10,max = 3x3x2x2 = 36; 这里不选3x3x3x1 = 27,因为3x3x2x2=36 > 3x3x3x1=27

找到规律，得到结论:当n>=5时，尽可能的分出3，分完3再分2。并且当最后剩下的长度为4时，不能再分成3和1了，应该分成2和2。

断言3x(n-3) >= 2x(n-2) 得到n>=5,也就是n大于等于5时候，成立。所以以上结论正确。

```
public class Problem14 {
    public static void main(String[] args) {
        System.out.println(cutBigNumberRope(120));
//        System.out.println(cuttingRope3(10));

    }

    /**
     * 暴力递归
     *
     * @return
     */
    public static int cuttingRope3(int n) {
        // 递归公式 f(n) = i * f(n-i),对于f(n-i)而言，和下面的子问题思路是一样的，已经切后的长度为(n-i)值本身可能比f(n-i)大,如果这种情况就不需要切了，
        // 此时(n-i) > f(n-i)
        if (n == 2) {
            return 1;
        }
        int max = -1;
        for (int i = 1; i < n; i++) {

            max = Math.max(max, Math.max(i * (n - i), i * cuttingRope3(n - i)));
        }
        return max;
    }

    /**
     * 贪心
     *
     * @param n
     * @return
     */
    public int cuttingRope(int n) {
        if (n == 2) {
            return 1;
        }
        if (n == 3) {
            return 2;
        }
        int threeCount = n / 3; // 记录3的个数
        if (n % 3 == 1) {
            // 如果余数为1，拿出一个3，组成4，分成2x2，这样结果最大
            threeCount--;
        }
        int twoCount = (n - 3 * threeCount) / 2;

        return (int) (Math.pow(3, threeCount) * Math.pow(2, twoCount));
    }

    /**
     * dp
     *
     * @param n
     * @return
     */
    public static int cuttingRope2(int n) {
        if (n == 2) {
            return 1;
        }
        if (n == 3) {
            return 2;
        }
        // 定义这个数组存储子问题的最优解(剪后值的最优解)，也就是剪一刀之后，剩下的长度的最大乘积(剪一刀后可以选择不再切，也可以选择再次切)
        int[] product = new int[n + 1];
        // 先把前面的解求出来，放到数组中保存，然后逐步算后面的
        product[1] = 1; // 剪后为1，所以乘积最大为1
        product[2] = 2; // 剪后为2，所以乘积最大为2
        product[3] = 3; // 剪后为3，所以乘积最大为3
        for (int i = 4; i <= n; i++) {
            int max = 0;
            for (int j = 1; j <= i / 2; j++) { // j取0到i/2而没有取全部范围是因为，总长度为4 ，1*3和3*1结果相同，所以只取一半范围就好，另一半直接对称了
                int currentProduct = product[j] * product[i - j];
                if (currentProduct > max) {
                    max = currentProduct;
                }
            }
            product[i] = max;
        }
        return product[n];
    }


    /**
     * 大数运算求余--dp(利用 BigInteger )当n=120时，会溢出int的最大值
     * @param n
     * @return
     */
    public static int cutBigNumberRope(int n){
        if (n == 2) {
            return 1;
        }
        if (n == 3) {
            return 2;
        }
        // 定义这个数组存储子问题的最优解(剪后值的最优解)，也就是剪一刀之后，剩下的长度的最大乘积(剪一刀后可以选择不再切，也可以选择再次切)
        BigInteger[] product = new BigInteger[n + 1];
        // 先把前面的解求出来，放到数组中保存，然后逐步算后面的
        product[1] = new BigInteger("1"); // 剪后为1，所以乘积最大为1
        product[2] = new BigInteger("2"); // 剪后为2，所以乘积最大为2
        product[3] = new BigInteger("3"); // 剪后为3，所以乘积最大为3
        for (int i = 4; i <= n; i++) {
            BigInteger max = new BigInteger("0");
            for (int j = 1; j <= i / 2; j++) { // j取0到i/2而没有取全部范围是因为，总长度为4 ，1*3和3*1结果相同，所以只取一半范围就好，另一半直接对称了
                BigInteger currentProduct = product[j].multiply(product[i - j]);
                if (currentProduct.compareTo(max)>0 ) {
                    max = currentProduct;
                }
            }
            product[i] = max;
        }
        return product[n].mod(new BigInteger("1000000007")).intValue();
    }
}
```
### 问题15: 
请实现一个函数，输入一个整数，输出该数二进制表示中 1 的个数。例如，把 9 表示成二进制是 1001，有 2 位是 1。因此，如果输入 9，则该函数输出 2。  

```
public class Problem15 {

    public static void main(String[] args) {
        System.out.println("      " + hammingWeight2(11));
    }

    public static int hammingWeight(int n) {
        return Integer.bitCount(n);
    }

    public static int hammingWeight2(int n) {
        // 左移:首先把n和1做与运算，判断n的最低位是不是1(与的结果不等于0则最高位为1)。接着把1左移一位得到2，再和n做与运算，就能判断n的次低位是不是1
        // 反复左移。
        int count = 0;
        int flag = 1;
        int i = 0;
        while (i < 32) {
            System.out.println("n=" + n + " flag=" + flag + " 与后=" + (n & flag));
            if ((n & flag) != 0) {
                count++;
            }
            flag = flag << 1;
            i++;
        }
        return count;
    }

    public static int hammingWeight3(int n) {
        // 右移: n 从最低位开始与1，如果最低位与1的结果是1，则计数+1，然后将n右移一位，将最低位去掉。直到 n 等于0
        int count = 0;
        while (n != 0) {
            count += n & 1;
            n = n >>> 1;
        }
        return count;
    }

    public static int hammingWeight4(int n) {
        // n & n-1 :把一个整数减去1后再和原整数做与运算，得到的效果相当于把整数的二进制表示中最右边的1变成0,用此方法可以将整数二进制表示中所有1变成0
        int count = 0;
        while (n != 0) {
            n = n & (n - 1);
            count++;
        }
        return count;
    }
}
```

### 问题16: 
实现函数double Power(double base, int exponent)，求base的exponent次方。不得使用库函数，同时不需要考虑大数问题。  

```
public class Problem16 {
    /**
     * n个x相乘，这样在n非常大时候会计算超时
     *
     * @param x
     * @param n
     * @return
     */
    public double myPow(double x, int n) {
        // x可以为正数，负数，0，  n可以为 正数，负数 0
        if (x == 0) {
            return 0;
        }
        if (n == 0 || x == 1) {
            return 1;
        }
        double result = 1;
        for (int i = 1; i <= Math.abs(n); i++) {
            result *= x;
        }
        if (n < 0) {
            result = 1 / result;
        }
        return result;
    }

    /**
     * 递归公式法
     *
     * @param x
     * @param n
     * @return
     */
    public double myPow2(double x, int n) {
        // x的n次方，当n为偶数时，x^n=x^(n/2) * x^(n/2)
        // 当n为奇数时，x^n = x^((n-1)/2) * x^((n-1)/2) * x
        return 0;
    }

    /**
     * 快速幂(二进制)
     *
     * @param x
     * @param n
     * @return
     */
    public static double myPow3(double x, int n) {
        /**
         * 存成long是因为当n为Java 代码中 int32 变量n∈[−2147483648,2147483647] ，
         * 因此当 n = -2147483648n=−2147483648 时执行 n = -n会因越界而赋值出错。
         * 解决方法是先将 n 存入 long 变量 N，后面用 N 操作即可。
         */
        long N = n;
        if (n < 0) {
            // 计算一个数的负次幂等于计算它倒数的正数次幂
            N = -N;
            x = 1 / x;
        }
        return fastPow(x, N);
    }

    /**
     * 用循环的快速二分幂(n*logn)
     *
     * @param x
     * @param n
     * @return
     */
    private static double fastPow(double x, long n) {
        if (n == 0) return 1;

        double result = 1; //定义最后计算结果

        while (n > 0) {
            if ((n & 1) == 1) {
                result *= x;
            }
            /**
             * 例如: 计算 6^11 , n=11 的二进制表示为1011 ，计算 6^11 等同于计算
             * 1*6^(2^0) *  1*6^(2^1) (0*6^(2^2)这项因为与1后的结果是0，所以不参与乘法)* 1*6^(2^3)。
             * 当上面的while循环运行时，如果n的二进制表示的最后一位是1，则将当前x累乘到result中
             */
            x *= x;
            n >>= 1;
        }
        return result;
    }

    public static void main(String[] args) {
        System.out.println(myPow3(6, 11));
    }
}
```

### 问题21: 输入一个整数数组，实现一个函数来调整该数组中数字的顺序，使得所有奇数位于数组的前半部分，所有偶数位于数组的后半部分。
```
public class Problem21 {
    public static int[] exchange(int[] nums) {
        /**
         * 遍历数组，如果当前元素是偶数，将此元素保存，然后将此元素后面的所有元素向前移动一个位置，然后将当前元素放到数组尾部，依次遍历
         * 缺点:时间复杂度O(n^2),对于输入数组[1,2,4,6,7]---------------->原书算法无法实现，死循环。
         */
        for (int i = 0; i < nums.length; i++) {
            if (nums[i] % 2 == 0) {
                // 当前元素是偶数，将后面的所有元素移位，然后将temp放在数组尾
                while (nums[i] % 2 == 0) {
                    int temp = nums[i];
                    for (int j = i; j < nums.length - 1; j++) {
                        nums[j] = nums[j + 1];
                    }
                    nums[nums.length - 1] = temp;
                }
            }
        }
        return nums;
    }

    /**
     * 两个指针:左指针指向偶数，右指针指向奇数，只要左指针还在右指针的左边，就交换。这样就可以实现数组左边是奇数，右边是偶数
     * @param nums
     * @return
     */
    public static int[] exchange1(int[] nums) {
        if (nums == null || nums.length == 0) {
            return nums;
        }

        int left = 0; //左指针指向偶数
        int right = nums.length - 1; // 右指针指向奇数
        while (left < right) {
            while (left < right && nums[left] % 2 != 0) { // 只要左指针指向的还不是偶数,就向右移动
                left++;
            }
            while (left < right && nums[right] % 2 == 0) { // 只要右指针指向的还不是奇数，就向左移动
                right--;
            }
            // 上边步骤是移动左右指针 ,这里移动后，交换位置

            if (left < right) { // 只有保证左指针还在右指针的左边，才可以进行交换，否则当left==right时候，会发生一次交换，属于无效交换。
                int temp = nums[left];
                nums[left] = nums[right];
                nums[right] = temp;
            }
        }
        return nums;
    }
}
```

### 问题22:输入一个链表，输出该链表中倒数第k个节点。为了符合大多数人的习惯，本题从1开始计数，即链表的尾节点是倒数第1个节点。例如，一个链表有6个节点，从头节点开始，它们的值依次是1、2、3、4、5、6。这个链表的倒数第3个节点是值为4的节点。
```
public class Problem22 {
    public class ListNode {
        int val;
        ListNode next;

        ListNode(int x) {
            val = x;
        }
    }

    public ListNode getKthFromEnd(ListNode head, int k) {
        if (head == null || k == 0) {
            return null;
        }
        ListNode first = head;
        ListNode then = head;
        // 先让first先走k-1步，然后两个指针同时走，当first走到链表尾时，then在倒数第k个节点
        for (int i = 0; i < k - 1; i++) {
            if (first.next == null) {
                return null;
            }
            first = first.next;
        }

        while (first.next != null) { // 只要当前first不在链表尾，就继续遍历。
            first = first.next;
            then = then.next;
        }
        return then;
    }
}

```

### 问题23: 给定一个链表，返回链表开始入环的第一个节点。 如果链表无环，则返回 null。为了表示给定链表中的环，我们使用整数 pos 来表示链表尾连接到链表中的位置（索引从 0 开始）。 如果 pos 是 -1，则在该链表中没有环。
```
public class Problem23 {
    public static void main(String[] args) {
        ListNode a = new ListNode(3);
        ListNode b = new ListNode(2);
        ListNode c = new ListNode(0);
        ListNode d = new ListNode(-4);
        a.next = b;
        b.next = c;
        c.next = d;
        d.next = b;
        System.out.println(detectCycle(a).val);
    }

    public static class ListNode {
        int val;
        ListNode next;

        ListNode(int x) {
            val = x;
            next = null;
        }
    }

    /**
     * 思路:要想找到链表环入口的结点，要先找出链表是否有环，用两个指针一快一慢从链表头出发，如果链表有环，一定会有快指针和慢指针
     * 指向同一个结点的时候。如果链表没有环，当快指针到达链表尾，都没有出现快指针和慢指针指向 同一个结点的时候，这时链表就不存在环。
     * 。如果链表存在环，第二步找环入口结点，设链表头到环入口处为x，环入口处到相遇点距离为y，相遇点到环入口处距离为z，
     * 则相遇时有:快指针走过的路程 = 2 * 慢指针走过的路程 -----> x+y+z+y= 2*(x+y) 得出x=z,所以找到相遇点后，
     * 将快指针指向头结点，当慢指针和快指针相遇时，此处就是环入口结点。
     *
     * @param head
     * @return
     */
    public static ListNode detectCycle(ListNode head) {
        // 检查输入
        if (head == null || head.next == null) {
            return null;
        }
        // 判断当前链表是否有环
        ListNode fast = head;
        ListNode slow = head;
        while (true) { //只要fast和slow值不相等，就继续遍历
            if (fast == null || fast.next == null) {
                // 如果fast走到尾结点都没和slow遇到，说明不存在环，直接返回
                return null;
            }

            /**
             * 上面为什么要判断fast是否为空 或者fast的下一个结点是否为空呢？假设在这里，快指针在倒数第二个结点处，
             * 那么经过下面的移动后，此时fast指在null处。假设快指针在倒数第三个结点处，那么经过下面的移动后，
             * 此时fast在尾结点。这两种情况都说明了链表无环，需要直接返回。
             *
             * node1 -> node2 -> node3 -> node4 -> null,
             * 以尾部还剩4个节点为例，说明下为什么 fast为null或者fast.next为null就说明链表到尾部了
             * 假设此时fast在node1处，那么两次遍历后，fast指在null
             * 假设此时fast在node2处，那么一次遍历后，fast.next指在null
             * 假设此时fast在node3处，那么一次遍历后，fast指在null
             * 以上情况中，所有情况都包含了，所以当fast为null或者fast.next为null就说明链表到尾部了
             */

            slow = slow.next; // 慢指针每次走一步
            fast = fast.next.next; //快指针每次走两步
            if (slow == fast) {
                break;
            }
        }

        /**
         * 此时快指针和慢指针同时到达相遇点，根据上面思路，两指针到达相遇点时，将快指针指回头结点，
         * 快指针和慢指针同时走，步长都为1，当再次相遇时，即为环入口结点。
         */
        fast = head;

        while (fast != slow) {
            slow = slow.next;
            fast = fast.next;
        }
        return fast;
    }
}
```

### 问题24:定义一个函数，输入一个链表的头节点，反转该链表并输出反转后链表的头节点。
```
public class Problem24 {
    public class ListNode {
        int val;
        ListNode next;

        ListNode(int x) {
            val = x;
        }
    }

    public ListNode reverseList(ListNode head) {
        if (head ==null || head.next ==null){
            return head;
        }
        // 开始反转链表
        ListNode reverseHead = null;  // 存储反转后的链表，当前为空链表，所以用null表示
        ListNode current = head; // 定义当前遍历的链表
        ListNode prev = null;  // 用于存储后面断开的链表
        while(current!=null){ // 只要当前current不是null,就继续将此结点从原链表中断开，然后指向反转链表头

            prev = current.next;  //将即将断开的链表存下来
            current.next = reverseHead; // 将当前结点指向反转链表头
            reverseHead = current; //更新反转链表头头结点指针
            current = prev; // 更新当前链表为去掉当前头结点的当前链表
        }
        return reverseHead;
    }
}
```

### 问题25:输入两个递增排序的链表，合并这两个链表并使新链表中的节点仍然是递增排序的。
```
public class Problem25 {
    public static class ListNode {
        int val;
        Problem25.ListNode next;
        ListNode(int x) {
            val = x;
        }
    }
    /**
     * 递归: 每次问题缩小一个规模
     *
     * @param l1
     * @param l2
     * @return
     */
    public ListNode mergeTwoLists(ListNode l1, ListNode l2) {
        if (l1 == null) {
            return l2;
        } else if (l2 == null) {
            return l1;
        }

        ListNode mergeHead = null;
        if (l1.val > l2.val) {
            mergeHead = l2;
            mergeHead.next = mergeTwoLists(l1, l2.next);

        } else {
            mergeHead = l1;
            mergeHead.next = mergeTwoLists(l1.next, l2);

        }
        return mergeHead;
    }

    /**
     * 迭代法
     *
     * @param l1
     * @param l2
     * @return
     */
    public static ListNode mergeTwoLists2(ListNode l1, ListNode l2) {
        if (l1 == null) {
            return l2;
        } else if (l2 == null) {
            return l1;
        }

        ListNode mergeHead = new ListNode(0);
        // 这里需要用一个指针指向这个合并链表头，如果不用指针的话，遍历合并后，合并链表头指向的是合并后最后一个结点，
        // 就无法返回链表头了，所以搞一个链表头等待链表合并完成，然后用这个指针去合并链表
        ListNode cur = mergeHead;
        while (l1 != null && l2 != null) {
            if (l1.val > l2.val) {
                cur.next = l2;
                cur = cur.next;
                l2 = l2.next;
            } else {
                cur.next = l1;
                cur = cur.next;
                l1 = l1.next;
            }
        }
        cur.next = l1 == null ? l2 : l1;
        return mergeHead.next;
    }
}
```

### 问题26：输入两棵二叉树A和B，判断B是不是A的子结构。(约定空树不是任意一个树的子结构) B是A的子结构， 即 A中有出现和B相同的结构和节点值。
```
public class Problem26 {

    public static class TreeNode {
        int val;
        TreeNode left;
        TreeNode right;

        TreeNode(int x) {
            val = x;
        }
    }

    /**
     * 思路:要想判断 B 是不是 A 的子结构，那么在 A 的子结构中根节点可以是 A 的任意一个节点，所以需要遍历 A ，并且在遍历的过程中判断以当前遍历到的这个节点
     * 为根结点的子结构是否包含树 B
     * <p>
     * 第一步：遍历树 A 的子节点
     * 第二步：在遍历的过程中，判断以当前遍历到的这个节点为根结点的子结构是否包含树 B
     *
     * @param A
     * @param B
     * @return
     */
    public boolean isSubStructure(TreeNode A, TreeNode B) {

        // 函数宏观语义为: 遍历树 A

        if (A == null || B == null) {
            return false;
        }

        boolean flag = false;

        if (A.val == B.val) {
            // 如果根节点相同，判断A的整棵树中是否包含B
            flag = tree1hasTree2(A, B);
        }
        if (!flag) {
            // 从左子树开始找
            flag = isSubStructure(A.left, B);
        }

        if (!flag) {
            // 找不到就继续从右子树开始找
            flag = isSubStructure(A.right, B);
        }

        return flag;
    }

    /**
     * 树2中是否包含树1
     *
     * @param one
     * @param two
     * @return
     */
    public boolean tree1hasTree2(TreeNode one, TreeNode two) {

        /**
         * 递归结束条件：因为进入这个函数时，两棵树都不是空的，如果根节点不同会直接跳出，那么如果根节点相同时，递归到什么时候才会跳出呢？
         * 如果B节点已经为null了，说明B已经匹配完成了
         */
        if (two == null) {
            return true;
        }

        if (one == null) {
            return false;
        }

        // 如果根节点相同，则左子树和右子树分别相等则认为树1包含树2
        if (one.val == two.val) {
            /**
             * 这里可能会出现 two.left这棵树先出现等于null，这时只能说明左子树完全匹配了，还要看右子树的匹配情况。
             * 只有 true && true，即two的左子树和one的左子树全匹配 且 two的右子树和one的右子树全匹配 才算是one包含two，此时返回true
             */
            return tree1hasTree2(one.left, two.left) && tree1hasTree2(one.right, two.right);
        } else {
            // 如果根节点不同，说明树1一定不会包含树2，则直接返回false
            return false;
        }
    }

    /**
     * 比第一种简洁一点的写法
     *
     * @param A
     * @param B
     * @return
     */
    public boolean isSubStructure2(TreeNode A, TreeNode B) {
        return (A != null && B != null) && (tree1hasTree2(A, B) || isSubStructure2(A.left, B) || isSubStructure2(A.right, B));
    }
}
```

### 问题27: 请完成一个函数，输入一个二叉树，该函数输出它的镜像。
```
public class Problem27 {
    public static class TreeNode {
        int val;
        Problem27.TreeNode left;
        Problem27.TreeNode right;

        TreeNode(int x) {
            val = x;
        }
    }

    // 输入一棵树，输出这棵树的镜像
    public TreeNode mirrorTree(TreeNode root) {
        if (root ==null){
            return root;
        }
        // 对输入的这棵二叉树，交换他的左子树和右子树，然后对他的左子树和右子树分别递归这个过程。
        swapTree(root);
        root.left = mirrorTree(root.left);
        root.right = mirrorTree(root.right);
        return root;
    }

    // 输入一棵树的根节点，此函数交换树的左子树和右子树
    public void swapTree(TreeNode root){
        TreeNode temp = root.left;
        root.left = root.right;
        root.right = temp;
    }
}
```

### 问题28: 请实现一个函数，用来判断一棵二叉树是不是对称的。如果一棵二叉树和它的镜像一样，那么它是对称的。例如，二叉树 [1,2,2,3,4,4,3] 是对称的。
```
public class Problem28 {
    public static class TreeNode {
        int val;
        Problem28.TreeNode left;
        Problem28.TreeNode right;

        TreeNode(int x) {
            val = x;
        }
    }

    /**
     * 思路: 首先得到这棵树的镜像，然后判断这棵树和它的镜像是否相同
     *
     * @param root
     * @return
     */
    public boolean isSymmetric(TreeNode root) {
        // 先得到一个树的镜像
        TreeNode mirrorNode = getMirror(root);

        // 比较这棵树
        return compare2Tree(root, mirrorNode);
    }

    /**
     * 得到一棵树的镜像
     *
     * @param root
     * @return
     */
    public TreeNode getMirror(TreeNode root) {
        if (root == null) {
            return root;
        }
        // 不能更改原树结构,这里新建一棵树
        TreeNode mirrorNode = new TreeNode(root.val);

        // 实质是发生了一次交换
        TreeNode temp = root.left;
        mirrorNode.left = getMirror(root.right);
        mirrorNode.right = getMirror(temp);

        return mirrorNode;
    }

    /**
     * 比较两棵树是否相同
     *
     * @param root1
     * @param root2
     * @return
     */
    public boolean compare2Tree(TreeNode root1, TreeNode root2) {

        // 如果两棵树的根节点都为空也是一种相等，那么说明已经全部比较过了，这时两棵树是相同的
        if (root1 == null && root2 == null) {
            return true;
        }
        // 如果遍历到其中任何一个根节点为空，说明已经不一样了，这时两棵树是不同的(且两棵树的根节点都存在)
        if (root1 == null || root2 == null) {
            return false;
        }

        // 比较两棵树的根节点，根节点不相等直接返回
        if (root1.val != root2.val) {
            return false;
        }
        // 到这里两棵树的根节点是相同的，那么继续分别比较两棵树的左子树和右子树
        return compare2Tree(root1.left, root2.left) && compare2Tree(root1.right, root2.right);
    }

    /**
     * 递归三步走:
     * (1)递归的函数要干什么？
     * 函数的作用是判断传入的两个树是否镜像。
     * 输入：TreeNode left, TreeNode right
     * 输出：是：true，不是：false
     * (2)递归停止的条件是什么？
     * 左节点和右节点都为空 -> 遍历到底了都长得一样 ->true
     * 左节点为空的时候右节点不为空，或反之 -> 长得不一样-> false
     * 左右节点值不相等 -> 长得不一样 -> false
     * (3)如何将问题缩小规模？(也就是从某层到下一层的关系是什么？)
     * 要想两棵树镜像，那么一棵树的左边要和二棵树的右边镜像，一棵树的右边要和二棵树的左边镜像
     * 调用递归函数传入左右和右左
     * 只有左右且右左镜像的时候，我们才能说这两棵树是镜像的
     *
     * 调用递归函数，我们想知道它的左右孩子是否镜像，传入的值是root的左孩子和右孩子。这之前记得判个root==null。
     *
     * @param root
     * @return
     */
    public boolean isSymmetric2(TreeNode root) {

        // 检查输入
        if (root == null) {
            return true;
        }

        return is2Symmetric(root.left, root.right);
    }

    /**
     * 用特殊遍历方式 比较两棵树是否为对称的
     *
     * @param root1
     * @param root2
     * @return
     */
    public boolean is2Symmetric(TreeNode root1, TreeNode root2) {

        // 递归结束条件(两棵树都遍历到底了，一直都是相同的，这时两棵树是对称的)
        if (root1 == null && root2 == null) {
            return true;
        }

        // 如果其中一棵树的根节点是空的，或者两棵树的根节点值不相等,都认为这两棵树不是对称的
        if (root1 == null || root2 == null || root1.val != root2.val) {
            return false;
        }

        /**
         * 两棵树根结点不是空，且相等，继续比较这两棵树的root1树的左子树和root2树的右子树是不是对称的，
         * 且 root1的右子树和root2的左子树是不是对称的。
          */
        return is2Symmetric(root1.left, root2.right) && is2Symmetric(root1.right, root2.left);
    }
}
```

### 问题31: 输入两个整数序列，第一个序列表示栈的压入顺序，请判断第二个序列是否为该栈的弹出顺序。假设压入栈的所有数字均不相等。例如，序列 {1,2,3,4,5} 是某栈的压栈序列，序列 {4,5,3,2,1} 是该压栈序列对应的一个弹出序列，但 {4,3,5,1,2} 就不可能是该压栈序列的弹出序列。
```
public class Problem31 {

    /**
     * 按题目要求，用一个辅助栈，按压入顺序入栈，按弹出顺序出栈，如果最后辅助栈不是空的，那么出栈序列不是合法的
     *
     * @param pushed
     * @param popped
     * @return
     */
    public static boolean validateStackSequences(int[] pushed, int[] popped) {
        LinkedList<Integer> stack = new LinkedList<>();
        // 出栈指针
        int pop = 0;
        // 按题目要求依次将压入序列压入辅助栈中
        for (int i : pushed) {
            stack.push(i);

            // 压入一个元素后，比较当前栈顶元素是否和出栈序列指针所指向的元素相等，如果相等则出栈。
            while (!stack.isEmpty() && stack.peek() == popped[pop]) {
                stack.pop();
                pop++;
            }
        }
        return stack.isEmpty();
    }
}
```
### 问题32:
(1)从上到下打印出二叉树的每个节点，同一层的节点按照从左到右的顺序打印。  
(2)从上到下按层打印二叉树，同一层的节点按从左到右的顺序打印，每一层打印到一行。  
(3)请实现一个函数按照之字形顺序打印二叉树，即第一行按照从左到右的顺序打印，第二层按照从右到左的顺序打印，第三行再按照从左到右的顺序打印，其他行以此类推。  
```
import java.util.ArrayList;
import java.util.Deque;
import java.util.LinkedList;
import java.util.List;

public class Problem32 {

    public static class TreeNode {
        int val;
        TreeNode left;
        TreeNode right;

        TreeNode(int x) {
            val = x;
        }
    }

    /**
     * 从上到下打印出二叉树的每个节点，同一层的节点按照从左到右的顺序打印。
     *
     * @param root
     * @return
     */
    public int[] levelOrder(TreeNode root) {
        if (root == null) {
            return new int[]{};
        }

        Deque<TreeNode> queue = new LinkedList<>();
        List<Integer> list = new ArrayList<>();

        queue.add(root);

        while (!queue.isEmpty()) {
            TreeNode current = queue.getFirst();
            if (current.left != null) {
                queue.add(current.left);
            }
            if (current.right != null) {
                queue.add(current.right);
            }
            list.add(current.val);
            queue.removeFirst();
        }

        int[] arr = new int[list.size()];
        for (int i = 0; i < arr.length; i++) {
            arr[i] = list.get(i);
        }
        return arr;
    }

    /**
     * 从上到下按层打印二叉树，同一层的节点按从左到右的顺序打印，每一层打印到一行。
     *
     * @param root
     * @return
     */
    public static List<List<Integer>> levelOrder2(TreeNode root) {
        if (root == null) {
            return new ArrayList<>();
        }

        Deque<TreeNode> queue = new LinkedList<>();
        List<List<Integer>> list = new ArrayList<>();
        List<Integer> array = new ArrayList<>();

        queue.addLast(root);
        int current = 1;
        int nextLevel = 0;
        while (!queue.isEmpty()) {

            TreeNode currentNode = queue.peekFirst();
            if (currentNode.left != null) {
                queue.addLast(currentNode.left);
                nextLevel++;
            }
            if (currentNode.right != null) {
                queue.addLast(currentNode.right);
                nextLevel++;
            }

            // 出栈
            TreeNode treeNode = queue.pollFirst();
            array.add(treeNode.val);
            current--;

            //
            if (current == 0) {
                list.add(array);
                array = new ArrayList<>();
                current = nextLevel;
                nextLevel = 0;
            }
        }
        return list;
    }

    /**
     * 请实现一个函数按照之字形顺序打印二叉树，即第一行按照从左到右的顺序打印，第二层按照从右到左的顺序打印，第三行再按照从左到右的顺序打印，其他行以此类推。
     *
     * @param root
     * @return
     */
    public static List<List<Integer>> levelOrder3(TreeNode root) {
        if (root == null) {
            return new ArrayList<>();
        }

        // 装最后结果的list
        List<List<Integer>> list = new ArrayList<>();
        // 用于存单层的列表
        List<Integer> printList = new ArrayList<>();
        // 第一个栈用于装单层的
        Deque<TreeNode> stackOne = new LinkedList<>();
        // 第二个栈用于遍历当前层时将下一层的结点放入第二个栈
        Deque<TreeNode> stackTwo = new LinkedList<>();

        stackOne.addFirst(root);
        // 用于当前层指针
        int current = 1;
        // 下一层的计数器
        int nextLevel = 0;
        // 层数(用于区分奇偶层)
        int levelCount = 1;

        // 只要这两个栈其中一个不是空，就继续循环
        while (!stackOne.isEmpty() || !stackTwo.isEmpty()) {
            // 拿出当前层结点
            TreeNode currentNode = stackOne.getFirst();
            // 当前遍历的层，需要区分奇偶后，把当前结点的下一层结点按顺序放入第二个栈
            if ((levelCount + 1) % 2 != 0) {
                // 奇数层 先放右结点再放左结点
                if (currentNode.right != null) {
                    stackTwo.addFirst(currentNode.right);
                    nextLevel++;
                }
                if (currentNode.left != null) {
                    stackTwo.addFirst(currentNode.left);
                    nextLevel++;
                }
            } else if ((levelCount + 1) % 2 == 0) {
                // 偶数层 先放左结点再放右结点
                if (currentNode.left != null) {
                    stackTwo.addFirst(currentNode.left);
                    nextLevel++;
                }
                if (currentNode.right != null) {
                    stackTwo.addFirst(currentNode.right);
                    nextLevel++;
                }
            }

            printList.add(stackOne.pollFirst().val);
            current--;
            if (current == 0) {
                // 层数加一
                levelCount++;
                // 将下一层的栈指向第一个栈
                stackOne = stackTwo;
                // 将第二个栈新建地址
                stackTwo = new LinkedList<>();
                // 本层放入list
                list.add(printList);
                printList = new ArrayList<>();
                current = nextLevel;
                nextLevel = 0;
            }

        }
        return list;
    }
}
```
### 问题33: 输入一个整数数组，判断该数组是不是某二叉搜索树的后序遍历结果。如果是则返回 true，否则返回 false。假设输入的数组的任意两个数字都互不相同。
```
import java.util.Arrays;

public class Problem33 {

    /**
     * 递归宏观定义: 输入后序遍历数组序列，返回true或者false，代表是不是一个合法的后序遍历序列
     *
     * @param postorder
     * @return
     */
    public static boolean verifyPostorder(int[] postorder) {
        // 检查输入,如果数组为空或者只有一个元素，认为是正确的。如果输入有两个元素，需要分出一个根结点，然后再看它的子节点是否符合要求
        if (postorder == null || postorder.length <= 1) {
            return true;
        }

        // 确定根节点下标
        int root = postorder[postorder.length - 1];

        // 确定左节点下标(需要注意确定左结点时是取不到根节点这个下标的，所以为length-1)
        int left = 0;
        for (; left < postorder.length - 1; ++left) {
            if (postorder[left] > root) {
                break;
            }
        }

        // 判断右子树是否合法
        for (int j = left; j < postorder.length; ++j) {
            if (postorder[j] < root) {
                return false;
            }
        }
        // 缩小问题规模
        return verifyPostorder(Arrays.copyOfRange(postorder, 0, left)) && verifyPostorder(Arrays.copyOfRange(postorder, left, postorder.length - 1));
    }

    public static void main(String[] args) {
        int[] arr = new int[]{1, 2, 5, 10, 6, 9, 4, 3};
        System.out.println(verifyPostorder(arr));
        int[] arr1 = new int[]{4, 8, 6, 12, 16, 14, 10};
        System.out.println(verifyPostorder(arr1));
    }
}
```

### 问题35:请实现 copyRandomList 函数，复制一个复杂链表。在复杂链表中，每个节点除了有一个 next 指针指向下一个节点，还有一个 random 指针指向链表中的任意节点或者 null。

```
import java.util.HashMap;
import java.util.Map;

public class Problem35 {
    static class Node {
        int val;
        Node next;
        Node random;

        public Node(int val) {
            this.val = val;
            this.next = null;
            this.random = null;
        }
    }

    /**
     * 用哈希表保存结点
     *
     * @param head
     * @return
     */
    public static Node copyRandomList(Node head) {
        if (head == null) {
            return head;
        }

        Map<Node, Node> map = new HashMap<>();
        // 用一个辅助头，用于追加复制后的结点
        Node newHead = new Node(1);
        // 保留头指针，便于下次遍历时用到这个头
        Node start = newHead;
        // 保留源链表的头指针
        Node originStart = head;
        // 先将原链表复制一份，构建哈希表
        while (head != null) {
            Node copyNode = new Node(head.val);
            newHead.next = copyNode;
            newHead = copyNode;
            // 缓存哈希表
            map.put(head, copyNode);
            head = head.next;
        }

        // 构建random指针
        // 把辅助头去掉作为新链表的头
        start = start.next;
        // 在遍历之前再次保留新链表头指针(此时不用再保留源链表的头了，已经用不到了)
        Node p = start;
        while (originStart != null) {
            // 遍历源链表，根据源链表构建新链表的random指针
            Node currentRandom = map.get(originStart.random);
            start.random = currentRandom;
            originStart = originStart.next;
            start = start.next;
        }
        return p;
    }

    /**
     * 先将复制链表的每个结点追加到源链表的后面，然后再将源链表和复制链表分开
     *
     * @param head
     * @return
     */
    public static Node copyRandomList2(Node head) {
        if (head == null) {
            return head;
        }
        // 保留源链表头指针
        Node headRefer = head;

        //复制源链表，将复制的结点追加到源链表每个结点后面，得到一个新链表
        while (head != null) {
            Node copyNode = new Node(head.val);
            // 暂存当前head后面的所有结点
            Node temp = head.next;
            head.next = copyNode;
            copyNode.next = temp;
            head = head.next.next;
        }

        // 设置复制链表的random指针
        Node newHeadRefer = headRefer;
        while (headRefer != null) {
            if (headRefer.random != null) {
                headRefer.next.random = headRefer.random.next;
            }
            headRefer = headRefer.next.next;
        }

        // 分离源链表和复制链表(！！！！！！！！！！！！！！必须删除原链表中的复制链表！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！)
        Node originHead = newHeadRefer;// 保留头引用
        Node copyNode = newHeadRefer.next;
        Node copyHead = copyNode;
        newHeadRefer.next = newHeadRefer.next.next;
        newHeadRefer = newHeadRefer.next;
        while (newHeadRefer != null) {

            copyNode.next = newHeadRefer.next;
            copyNode = copyNode.next;
            newHeadRefer.next = newHeadRefer.next.next;
            newHeadRefer = newHeadRefer.next;

        }
        return copyHead;
    }
}
```
今天拷贝复杂链表的题，主要的点就在于输入的链表的地址只能存原链表，leetcode会去检查输入的地址是否被改变，
增进了深拷贝和浅拷贝的区别。之前的错误一直是把源链表和复制链表弄到一个链表里有，这块地址存的东西就被改变了，
所以检查的是这块地址的东西，所以在复制的时候改变了这块地址的内容，复制完后，需要把这块地址存的东西复原会去，
这样leetcode的检查就不会知道有代码曾经改变过。之前一直是把复制链表单独弄好后，没有复原源链表

### 问题36: 输入一棵二叉搜索树，将该二叉搜索树转换成一个排序的循环双向链表。要求不能创建任何新的节点，只能调整树中节点指针的指向。
```
public class Problem36 {

    // 双向链表的头指针
    public Node head;
    // 指向双向链表尾的指针(从head开始移动的)
    public Node pre;

    class Node {
        public int val;
        public Node left;
        public Node right;

        public Node() {
        }

        public Node(int _val) {
            val = _val;
        }

        public Node(int _val, Node _left, Node _right) {
            val = _val;
            left = _left;
            right = _right;
        }
    }

    /**
     * 将一棵二叉树转换为排序的双向链表
     *
     * @param root
     * @return
     */
    public Node treeToDoublyList(Node root) {
        // 检查输入
        if (root == null) {
            return root;
        }
        treeToList(root);
        // 头尾相连
        head.left = pre;
        pre.right = head;

        return head;
    }

    /**
     * 将一棵二叉树转换为双向链表追加到给定结点上
     *
     * @param root
     */
    public void treeToList(Node root) {
        if (root == null) {
            return;
        }
        treeToList(root.left);
        // 双向链表尾指针指向的是不是null
        if (pre == null) {
            // 尾指针当前指向null，则将当前访问结点挂到双向链表头
            head = root;
        } else {
            // 尾指针指向不为null，则将当前尾指针指向的节点右指针指向当前结点
            pre.right = root;
        }

        root.left = pre;
        // 更新双向链表尾指针的指向，指向当前结点
        pre = root;
        treeToList(root.right);
    }
}
```

### 问题38:输入一个字符串，打印出该字符串中字符的所有排列。你可以以任意顺序返回这个字符串数组，但里面不能有重复元素。

```java
import java.util.HashSet;
import java.util.Set;

/**
 * @author AK
 * @date 2021/2/22 16:29
 */
public class Solution_38 {

    /**
     * 用一个全局变量set来保存所有结果
     */
    private static Set<String> set = new HashSet<>();

    /**
     * 输入一个字符串，返回所有字符串中字符的所有组合
     *
     * @param s
     * @return
     */
    public static String[] permutation(String s) {
        if (s == null || s.isEmpty()) {
            // 如果是空字符串则直接返回空数组结果
            return new String[0];
        }
        permutation(s.toCharArray(), 0);
        // 用局部变量把结果保存下来
        Set<String> copySet = new HashSet<>(set);
        // 把全局变量set清空，便于oj测试
        set.clear();
        return copySet.toArray(new String[0]);
    }

    /**
     * 输入一个字符数组，和头下标， 把所有字符组合结果存入set中
     *
     * @param chars
     * @param index
     */
    public static void permutation(char[] chars, int index) {
        if (index == chars.length) {
            // 如果当前下标和输入字符数组容量相同，则将字符结果存入set
            set.add(new String(chars));
        } else {
            // 否则用for循环从 头下标 开始遍历，直到下标指到字符数组中最后一个字符
            for (int i = index; i <= chars.length - 1; i++) {
                // 交换字符数组 头下标 和 当前遍历到的下标 位置
                swap(chars, i, index);
                // 递归 -> 把问题缩小
                permutation(chars, index + 1);
                // 把字符数组还原
                swap(chars, i, index);
            }
        }
    }

    /**
     * 交换位置
     *
     * @param arr
     * @param x
     * @param y
     */
    public static void swap(char[] arr, int x, int y) {
        char temp = arr[x];
        arr[x] = arr[y];
        arr[y] = temp;
    }
}
```

### 问题39:数组中有一个数字出现的次数超过数组长度的一半，请找出这个数字。

```java
/**
 * @author AK
 * @date 2021/2/24 9:52
 */
public class Solution_39 {
    /**
     * 众数:数组中超过一半的数
     * 摩尔投票法:这种方法只能在确定数组中一定存在众数时才可以用！！就是说
     * 如果一个存在众数的数组，如果用一个众数去和数组中的非众数去抵消，最终剩下的一定是众数。
     * 具体做法:先拿出数组中第一个数作为众数候选人，初始化统计次数为1。当开始遍历时，如果遇到
     * 和这个数相同的数，则增加统计次数，否则减少统计次数，当统计次数变为0时，则重新选一个数字作为候选人
     * ，最终得到的候选人一定是众数
     * <p>
     * nums:      [7,7,5,7,5,1,5,7,5,5,7,7,7,7,7,7]
     * candidate: [7,7,7,7,7,7,5,5,5,5,5,5,7,7,7,7]
     * count:     [1,2,1,2,1,0,1,0,1,2,1,0,1,2,3,4]
     *
     * @param nums
     * @return
     */
    public int majorityElement(int[] nums) {
        // 先把第一个数当作候选人
        int candidate = nums[0];
        // 把次数设置为1
        int count = 1;
//        List<Integer> candidateList = new ArrayList<>();
//        List<Integer> countList = new ArrayList<>();
//        candidateList.add(nums[0]);
//        countList.add(1);
        for (int i = 1; i <= nums.length - 1; i++) {
            // 如果统计次数为0时，把当前遍历的数当作候选人，然后统计次数递增后其他什么也不做
            if (count == 0) {
                candidate = nums[i];
                count++;
            } else if (candidate == nums[i]) {
                // 如果统计次数不是0，且当前遍历的数和当前候选人相等，则统计次数递增
                count++;
            } else {
                // 如果当前遍历的数和当前候选人不相等，则统计次数递减
                count--;
            }
//            candidateList.add(candidate);
//            countList.add(count);
        }
//        System.out.println("          :" + Arrays.toString(nums));
//        System.out.println("candidate: " + candidateList);
//        System.out.println("count    : " + countList);
        return candidate;
    }

    public static void main(String[] args) {
        int[] arr = new int[]{7, 7, 5, 7, 5, 1, 5, 7, 5, 5, 7, 7, 7, 7, 7, 7};
        int[] arr1 = new int[]{1, 2, 3, 2, 2, 2, 5, 4, 2};
        int i = new Solution_39().majorityElement(arr);
        System.out.println(i);
    }
}
```

### 问题40: 输入整数数组 `arr` ，找出其中最小的 `k` 个数。例如，输入4、5、1、6、2、7、3、8这8个数字，则最小的4个数字是1、2、3、4。

```java
import java.util.PriorityQueue;
import java.util.Queue;

/**
 * @author AK
 * @date 2021/2/27 15:46
 */
public class Solution_40 {

    /**
     * 堆也是一棵二叉树。
     * 大根堆的根节点都比子节点大，所以叫大根堆，大根堆能很容易获取到堆最大值。只要在元素入堆时跟堆顶的最大值做比较来决定是否入堆，
     * 很容易就能获取到一个数组的前k小元素，因为比堆顶还大的不允许入堆
     * <p>
     * 小根堆的根节点都比子节点小，所以叫小根堆，小根堆能很容易获取到堆最小值。只要在元素入堆时跟堆顶的最小值做比较来决定是否入堆，
     * 很容易就能获取到一个数组的前k大元素，因为比堆顶还小的不允许入堆
     * <p>
     * 需要用一个数据结构来装k个数，并且这个数据结构可以很方便地拿到k个数中的最大值，
     * 使用堆来解决前k小数字问题，并且需要选择大根堆，因为大根堆能很方便地拿到堆中最大值。
     *
     * @param arr
     * @param k
     * @return
     */
    public int[] getLeastNumbers(int[] arr, int k) {
        // 对输入进行检查
        if (arr == null || arr.length == 0 || k == 0 || k > arr.length) {
            return new int[0];
        }
        // 用于保存返回结果
        int[] res = new int[k];
        // PriorityQueue默认为小根堆，重写Comparator使其变为大根堆
        Queue<Integer> queue = new PriorityQueue<>((x1, x2) -> x2 - x1);
        for (int i : arr) {
            // 如果堆中元素个数小于k，则通通入队
            if (queue.size() < k) {
                queue.add(i);
            } else {
                // 队列中元素数量已经大于等于k了。如果当前遍历元素比大根堆堆顶小，则移除堆顶，把当前遍历元素入堆
                if (i < queue.peek()) {
                    queue.poll();
                    queue.add(i);
                }
            }
        }
        // 把队列中元素放入返回结果中
        for (int i = 1; i <= k; i++) {
            res[i - 1] = queue.poll();
        }
        return res;
    }
}
```

