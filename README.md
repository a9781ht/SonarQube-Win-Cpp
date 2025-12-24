# Windows C++ 示範專案導入 SonarQube, Google Test, Code coverage

此為示範專案，教導如何將 Windows 平台的 C++ 專案導入到 SonarQube，並整合 Unit Test 與 Code Coverage。

---

## 使用版本

| 工具 | 版本 |
|------|------|
| SonarQube | Developer Edition v10.6 |
| Build Wrapper | Cpp Win x86 |
| SonarScanner | CLI 6.1.0.4477 |

---

## 前置作業

1. 透過個人 GitLab 帳號的 **Personal Access Token** 將該 C++ 專案加入到 SonarQube

2. 選擇 **Previous Version** 當作 New Code 的 baseline

3. 將 SonarQube 的 URL 儲存在 GitLab 的**全域變數**裡，取名為 `SONAR_HOST_URL`

4. 將該 C++ 專案在 SonarQube 產生出來的 **Project Key** 儲存到 GitLab 的 **Settings → CI/CD → Variables** 裡，取名為 `SONARQUBE_PROJECT_KEY`

5. 將該 C++ 專案在 SonarQube 產生出來的 **Token** 儲存到 GitLab 的 **Settings → CI/CD → Variables** 裡，取名為 `SONAR_TOKEN`

---

## 專案修改

1. 修改 `.gitlab-ci.yml` 裡的 `image`，選一個可以編譯你軟體的環境，並且該環境也需要擁有 `git` 與 `7z` 等工具

2. 修改 `.gitlab-ci.yml` 裡的 `tag`，選一個 GitLab 有提供的 Windows 環境去啟動 image

3. 修改 `SQAnalysis.bat` 裡的 `version` 軟體版本

4. 修改 `SQAnalysis.bat` 裡的 `release` 分支前綴

---

## 開始分析

| 分支類型 | New Code 區分方式 |
|----------|-------------------|
| `master` | 使用 `SQAnalysis.bat` 裡的 `Version` 變數 |
| `release` | 使用 `SQAnalysis.bat` 裡的 `Version` 變數 |
| `feature` / `bug` | 使用 `.gitlab-ci.yml` 裡的 `NewCodeRefBranch` 變數 |

---

## 測試結果報表

1. vstest.console.exe 只支援輸出 [Trx, Console, Html 這三種格式的測試結果報表](https://github.com/microsoft/vstest-docs/blob/main/docs/report.md)

2. 要在 GitLab 上顯示，需要 [JUnit 格式](https://docs.gitlab.com/ci/testing/unit_test_reports/#file-format-and-size-limits)，需搭配第三方工具 JunitXml.TestLogger。然後在 job:artifacts:reports:junit 欄位指定該測試結果報表

3. 要在 SonarQube 上顯示，C++ 需要 [SonarQube Generic Test Execution Format 格式](https://docs.sonarsource.com/sonarqube-server/10.6/analyzing-source-code/test-coverage/generic-test-data#generic-test-execution)，市面上沒有現成的轉換工具，需要自行轉換。然後在 sonar.testExecutionReportPaths 欄位指定該測試結果報表

---

## 測試覆蓋率報表

1. vstest.console.exe 只支援捕獲 [*.coverage, *.cobertura.xml, *.coveragexml 這三種格式的覆蓋率報表](https://learn.microsoft.com/zh-tw/visualstudio/test/customizing-code-coverage-analysis?view=visualstudio#code-coverage-formats)

2. 要在 GitLab 上顯示，需要 [Cobertura 格式 *.cobertura.xml](https://docs.gitlab.com/ci/testing/code_coverage/?tab=C%2FC%2B%2B+and+Rust#coverage-visualization)，可以直接透過 vstest.console.exe 捕獲。然後在 job:artifacts:reports:coverage_report:path 欄位指定該測試覆蓋率報表

3. 要在 SonarQube 上顯示，C++ 可以是 [XML 格式 *.coveragexml 或是 SonarQube Generic Code Coverage Format 格式](https://docs.sonarsource.com/sonarqube-server/10.6/analyzing-source-code/test-coverage/test-coverage-parameters#cfamily)，前者可以透過第三方工具 ReportGenerator 將 *.cobertura.xml 轉成 *.coveragexml。然後在 sonar.cfamily.vscoveragexml.reportsPath 欄位指定該測試覆蓋率報表；後者透過也可以透過第三方工具 ReportGenerator 將 *.cobertura.xml 直接轉成 SonarQube 格式。然後在 sonar.coverageReportPaths 欄位指定該測試覆蓋率報表

---

## 備註

<details>
  <summary>專案格式</summary>
  
  Microsoft C++ 專案（`.vcxproj`）只能使用 **Non-SDK Style** 格式，不像 .NET Core/5+/Framework4.6.1+ 專案可以使用 SDK-Style。

</details>

<details>
  <summary>套件管理方式</summary>
  
  本專案使用的 `Microsoft.googletest.v140.windesktop.msvcstl.static.rt-dyn` 是舊式 native 套件，透過 `.targets` 檔案設定路徑，**不支援 PackageReference 格式**，因此只能使用 `packages.config` 來管理套件。
  
</details>

<details>
  <summary>套件還原方式</summary>
 
  `packages.config` 格式在命令列上無法透過 MSBuild 的 `/restore` 選項自動還原套件，必須額外使用 `nuget.exe restore` 來還原。

</details>

<details>
  <summary>其他</summary>
  
  > vstest.console.exe
  1. 雖然 GoogleTest 會產生自己的可執行檔，但本專案選用 vstest.console.exe，以利統一各語言的測試平台。但不要使用 Visual Studio 內建路徑下的 vstest.console.exe (C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe) 因為他在蒐集覆蓋率時還需手動調用 datacollector.exe 的協助，建議可以直接使用 Microsoft.Testing.Platform (NuGet package) 裡的 vstest.console.exe，其整合的較為完整，包含對於 Native C++ code coverage 的支援
  2. 由於 vstest.console.exe 執行一次只能捕獲一種測試覆蓋率的格式，為了兼容 SonarQube 和 GitLab，起初是可以透過先產生 Binary 格式，然後再利用 CodeCoverage.exe 將其分別轉成 Cobertura 格式和 XML 格式，但此工具已經不維護了，連同 Microsoft.CodeCoverage.Console 工具也是。目前官方只建議使用 dotnet-coverage 這套工具，但它需要 .NET SDK。以 C++ 的情境來說，可以改使用第三方工具 ReportGenerator
  3. 因此架構會變成：vstest.console.exe 產生 GitLab 需要的 Cobertura 格式，ReportGenerator 再將其轉換成 SonarQube 要的 XML 格式或是直接轉成 SonarQube 格式，甚至也可以多轉出一份易閱讀的 HTML 格式

  > SonarQube
  1. SonarQube 支援的 Cobertura 格式，和 vstest.console.exe 產出的 Cobertura 格式，不太一樣。前者為標準完整的，而後者為簡化版，省略了 <sources> 元素用來指定原始碼的根目錄，讓工具知道如何找到對應的檔案
  2. 若透過 ReportGenerator 轉出 XML 格式會有很多份，每個測試案例就是獨立一份，所以 sonar.cfamily.vscoveragexml.reportsPath 欄位支援 wildcard；而轉出 SonarQube 格式只會有一份，預設叫做 SonarQube.xml，所以 sonar.coverageReportPaths 欄位不支援 wildcard

  > GitLab
  1. GitLab 顯示 code coverage 的地方會在 Merge Request 裡面，如果想在 Jobs 頁面上顯示 code coverage 的百分比，需要使用 coverage 關鍵字 (透過 ReportGenerator 產生 TeamCitySummary 格式，並從 console output 中提取覆蓋率百分比)，其中 CodeCoverageS 代表 Statement Coverage 語句覆蓋率

</details>
