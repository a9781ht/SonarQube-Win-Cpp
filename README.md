# SonarQube Windows C++ 專案導入示範

此為示範專案，教導如何將 Windows 平台的 C++ 專案導入到 SonarQube。

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

## 備註

### 1. 專案格式

Microsoft C++ 專案（`.vcxproj`）只能使用 **Non-SDK Style** 格式，不像 .NET Core/5+/Framework4.6.1+ 專案可以使用 SDK-Style。

### 2. 套件管理方式

本專案使用的 `Microsoft.googletest.v140.windesktop.msvcstl.static.rt-dyn` 是舊式 native 套件，透過 `.targets` 檔案設定路徑，**不支援 PackageReference 格式**，因此只能使用 `packages.config` 來管理套件。

### 3. 套件還原方式

`packages.config` 格式在命令列上無法透過 MSBuild 的 `/restore` 選項自動還原套件，必須額外使用 `nuget.exe restore` 來還原。
