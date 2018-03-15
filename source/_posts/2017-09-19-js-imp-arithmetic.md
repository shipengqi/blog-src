---
title: Javascript实现 冒泡 快排 二分查找 矩阵转置
date: 2017-09-19 22:31:33
categories: ["Javascript"]
---
冒泡排序,快排,二分查找的javascript实现
<!-- more -->
``` javascript
//冒泡排序
function sort(arr) {
    var len = arr.length,
        i;
    while (len > 0){
        for(i = 0;i < len -1; i++){
            if(arr[i] > arr[i+1]){
                var temp = arr[i];
                arr[i] = arr[i+1];
                arr[i+1] = temp;
            }
        }
        len --;
    }

}

//快排
function quicksort(arr) {
    if(arr.length <= 1){
        return arr;
    }
    var pivotIndex = Math.floor(arr.length/2);

    var left = [],
        right = [];
    for(var i = 0;i < arr.length;i++){
        if(arr[i] < arr[pivotIndex]){
            left.push(arr[i])
        }else if(arr[i] > arr[pivotIndex]){
            right.push(arr[i])
        }
    }
    return quicksort(left).concat([arr[pivotIndex]],quicksort(right))
}

//二分查找
function binarysearch(arr,dest,s,e) {
    var start = s || 0;
    var end = e || arr.length-1;
    var middle = Math.floor((start+end)/2);
    if(arr[middle] === dest){
        return middle;
    }
    if(dest < arr[middle]){
        return binarysearch(arr,dest,0,middle-1);
    }else{
        return binarysearch(arr,dest,middle+1,end);
    }
    return false;
}

var arr = [0,1,2,3,4,5,6,7,8,9,10,11,12];

console.log(binarysearch(arr,4));

//矩阵转置

// 定义一个矩阵（二维数据）
var arr1 = [
    [1, 2, 3, 4],
    [5, 6, 6, 6],
    [7, 6, 7, 8],
    [8, 5, 3, 3]
];
var arr2 = [];
//确定新数组有多少行
for(var i = 0; i < arr1[0].length; i ++){
  arr2[i] = [];
}
//动态添加数据
//遍历原数组
for(var i = 0; i < arr1.length; i ++){
  for(var j = 0; j < arr1[i].length; j ++){
    arr2[j][i] = arr1[i][j];
  }
}
console.log(arr2);
```