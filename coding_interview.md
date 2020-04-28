剑指offer题解:
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

### 问题5: