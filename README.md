# Solidity-Group-Project

原本將合約拆分成好幾份，但 external, internal, view 等等的一堆限制害我一直搞定不了 Bug，所以就全部寫成一份了。

已經部署在 Sepolia 測試網上，合約地址：0x7660fFdD34a455F02D329E341F7A84642d3731CE，經測試功能都是正常的。

有叫 ChatGPT 幫我寫個前端，但是很爛而且功能沒辦法正確執行，就先做到這了。

抱歉寫得很爛甚至沒加註解，但是 function 名稱我寫得很直白，剩下我會慢慢補上的。


以下by Janet 9/10
1. 由於要跟前端互相溝通（？）有更新合約，新部署地址：0xfB5AF694DE274d4378B342F07b2907cc6BdDf253
2. 已經把 templates 中所有前端的合約地址都換成新的、ABI 代碼也是（應該啦）、ABI 檔案也更新了；目前應該可以由 index 頁面去到各功能頁面、跟老師教的一樣
3. 功能實踐狀態：
4. 存款頁應該是最正常可運行的，可存錢也正確顯示金額
5. 借貸頁開始有bug：由於借貸應該需要抵押資產，讓我突然想到是不是前端要能辨認用戶是誰、記住他所存過的資產、並從中選擇、同時不能借超過一定數額。目前卡在前端無法辨識身份，所以下拉選單總是沒有資產可選擇，跟不確定剩下功能實踐邏輯會不會跟我想的不同，所以就給Perry繼續看有沒有辦法把邏輯跟前端搭起來
6. 其他頁面也都有bug，而且應該需要等前面的頁面功能完善才有辦法繼續
7. 沒寫 admin頁面，因為感覺核心功能先做完再做應該可吧哈哈


kevin的晚间播报：
已经将p2p改好了多界面，需要在borrow.js里加入数据库，请看881行！
