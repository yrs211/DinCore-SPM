//
//  DinCore+Home.swift
//  DinCore
//
//  Created by 郑少玲 on 2021/5/31.
//

import Foundation
import RxSwift

extension DinCore {
    public static func createHome(name: String, language: String, success: ((DinHome) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.createHome(name: name, language: language)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let homeID = returnDict["home_id"] as? String {
                let newHome = DinHome()
                newHome.id = homeID
                newHome.name = name
                DinCore.user?.addHomes([newHome])
                success?(newHome)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func renameHome(homeID: String, name: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.renameHome(homeID: homeID, name: name)
        DinHttpProvider.request(request) { result in
            for home in DinCore.user?.homes ?? [] where home.id == homeID {
                home.name = name
                break
            }
            // 判断是不是修改了当前的home
            if homeID == DinCore.user?.curHome?.id {
                DinCore.user?.curHome?.name = name
            }
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func deleteHome(homeID: String, success: (() -> Void)?, fail: ApiFailure?) {
        let reqeust = DinHomeRequest.deleteHome(homeID: homeID)
        DinHttpProvider.request(reqeust) { result in
            DinCore.user?.deleteHome(withID: homeID)
            if homeID == DinCore.user?.curHome?.id, let firstHome = DinCore.user?.homes?.first {
                DinCore.switchToHome(homeID: firstHome.id, homeDidSet: nil, success: nil, fail: nil)
            }
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func listHomes(success: (([DinHome]) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.listHomes
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let tempHomes = returnDict["list_homes"] as? [[String: Any]], let homes = [DinHome].deserialize(from: tempHomes) {
                var resultHomes: [DinHome] = []
                for optionalHome in homes {
                    if let home = optionalHome {
                        resultHomes.append(home)
                    }
                }
                DinCore.user?.setHomeList(resultHomes)
                success?(resultHomes)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func syncCurrentHome(success: (() -> Void)?, fail: ApiFailure?) {
        DinCore.listHomes { (homes) in
            var isCurrentHomeExsit = false
            for home in homes where home.id == DinCore.user?.curHome?.id {
                isCurrentHomeExsit = true
            }
            if isCurrentHomeExsit {
                DinCore.switchToHome(homeID: DinCore.user?.curHome?.id ?? "", homeDidSet: nil, success: success, fail: fail)
            } else if let firstHomeID = homes.first?.id {
                DinCore.switchToHome(homeID: firstHomeID, homeDidSet: nil, success: success, fail: fail)
            } else {
                DinCore.switchToHome(homeID: "", homeDidSet: nil, success: success, fail: fail)
            }
        } fail: { error in
            fail?(error)
        }

    }


    public static func generateHomeInvitationCode(homeID: String, level: Int, success: ((String) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.generateHomeInvitationCode(homeID: homeID, level: level)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let code = returnDict["code"] as? String {
                success?(code)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func verifyHomeInvitationCode(code: String, success: ((DinHome) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.verifyHomeInvitationCode(code: code)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let home = DinHome.deserialize(from: returnDict) {
                DinCore.user?.addHomes([home])
                // 这里又换主机干什么？
//                DinCore.switchToHome(homeID: home.id, success: nil, fail: nil)
                success?(home)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func listHomeMembers(homeID: String, pageSize: Int, level: Int, joinTime: Int, success: (([DinMember]) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.listHomeMembers(homeID: homeID, pageSize: pageSize, level: level, joinTime: joinTime)
        DinHttpProvider.request(request) { result in
            if let returnResult = result, let listMemebers = returnResult["list_members"] as? [[String: Any]] {
                let optionalMembers = [DinMember].deserialize(from: listMemebers)
                var members: [DinMember] = []
                for optionMember in optionalMembers ?? [] {
                    if let member = optionMember {
                        members.append(member)
                    }
                }
                if homeID == DinCore.user?.curHome?.id {
                    DinCore.user?.curHome?.setMembers(members)
                }
                success?(members)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func updateMemberInfo(homeID: String, member: DinMember, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.updateMemberInfo(homeID: homeID, member: member)
        DinHttpProvider.request(request) { result in
            if member.userId == DinCore.user?.id {
                DinCore.user?.curHome?.level = member.level
            }
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func deleteMember(homeID: String, userID: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.deleteMember(homeID: homeID, userID: userID)
        DinHttpProvider.request(request) { result in
            // 删除自己
            if userID == DinCore.user?.id {
                // 删除对应家庭
                DinCore.user?.deleteHome(withID: homeID)
                // 如果删除的是当前家庭
                if homeID == DinCore.user?.curHome?.id, let firstHome = DinCore.user?.homes?.first {
                    DinCore.switchToHome(homeID: firstHome.id, homeDidSet: nil, success: nil, fail: nil)
                } else if DinCore.user?.homes?.count ?? 0 == 0 {
                    DinCore.switchToHome(homeID: "", homeDidSet: nil, success: nil, fail: nil)
                }
            }
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func getHomeDetailInfo(homeID: String, success: ((DinHome) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.getHomeDetailInfo(homeID: homeID)
        DinHttpProvider.request(request) { result in
            if let returnResult = result, let home = DinHome.deserialize(from: returnResult) {
                home.id = homeID
                success?(home)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    /// 每一个家庭都有msct的通讯，用于服务器主动通知客户端
    /// - Parameters:
    ///   - homeID: 家庭ID
    ///   - success: 成功回调
    ///   - fail: 失败回调
    static func msctLogin(homeID: String, success: (([String: Any]?) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.msctLogin(homeID: homeID)
        DinHttpProvider.request(request) { result in
            success?(result)
        } fail: { error in
            fail?(error)
        }
    }

    /// 每一个家庭都有msct的通讯，用于服务器主动通知客户端
    /// - Parameters:
    ///   - homeID: 家庭ID
    ///   - success: 成功回调
    ///   - fail: 失败回调
    static func msctLogout(homeID: String, success: (([String: Any]?) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.msctLogout(homeID: homeID)
        DinHttpProvider.request(request) { result in
            success?(result)
        } fail: { error in
            fail?(error)
        }
    }

    public static func addHomeContact(homeID: String, SMS: Bool, systemSMS: Bool, infoSMS: Bool, sosSMS: Bool, contacts: [DinHomeContact], success: (() -> Void)?, fail: ApiFailure?) {
        var contactArray: [[String: Any]] = []
        for contact in contacts {
            let contactDict = ["name": contact.name, "phone": contact.phone]
            contactArray.append(contactDict)
        }
        let request = DinHomeRequest.addHomeContact(homeID: homeID, SMS: SMS, systemSMS: systemSMS, infoSMS: infoSMS, sosSMS: sosSMS, contacts: contactArray)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func listContacts(homeID: String, pageSize: Int, contactID: String, success: (([DinHomeContact]) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.listContacts(homeID: homeID, pageSize: pageSize, contactID: contactID)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let contactsDict = returnDict["list_contacts"] as? [[String: Any]] {
                let optionalContacts = [DinHomeContact].deserialize(from: contactsDict)
                var contacts: [DinHomeContact] = []
                optionalContacts?.forEach {
                    if let contact = $0 {
                        contacts.append(contact)
                    }
                }
                success?(contacts)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func deleteContact(homeID: String, contactID: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.deleteContact(homeID: homeID, contactID: contactID)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func updateContact(homeID: String, contact: DinHomeContact, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.updateContact(homeID: homeID, contact: contact)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func updateHomePushLanguage(homeID: String, language: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.updateHomePushLanguage(homeID: homeID, language: language)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func getHomePushLanguage(homeID: String, success: ((String) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.getHomePushLanguage(homeID: homeID)
        DinHttpProvider.request(request) { result in
            if let returnResult = result, let language = returnResult["language"] as? String {
                success?(language)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func getMemberPWDInfo(panelID: String, userID: String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.getMemberPWDInfo(panelID: panelID,
                                                      homeID: DinCore.user?.curHome?.id ?? "",
                                                      userID: userID)
        DinHttpProvider.request(request) { result in
            if let returnResult = result {
                success?(returnResult)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func resetMemberPWDInfo(panelID: String, userID: String, success: ((String) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.resetMemberPWDInfo(panelID: panelID,
                                                        homeID: DinCore.user?.curHome?.id ?? "",
                                                        userID: userID)
        DinHttpProvider.request(request) { result in
            if let returnResult = result {
                success?((returnResult["pwd"] as? String) ?? "")
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func updateMemberPWDInfo(panelID: String, userID: String, enable: Bool, success: ((String) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.updateMemberPWDInfo(panelID: panelID,
                                                         homeID: DinCore.user?.curHome?.id ?? "",
                                                         userID: userID,
                                                         enable: enable)
        DinHttpProvider.request(request) { result in
            if let returnResult = result {
                success?((returnResult["pwd"] as? String) ?? "")
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    /// 切换家庭
    /// 在家庭列表中寻找需要切换的家庭，如果有，先设置缓存再请求服务器获取家庭详情
    /// - Parameters:
    ///   - homeID: 家庭ID
    ///   - homeDidSet: 在家庭列表中找到了，完成缓存的预设（如果没有，找家庭列表，家庭列表没有，置空直接返回，不请求详情），紧接着去请求家庭详情
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func switchToHome(homeID: String,
                                    homeDidSet: (() -> Void)?,
                                    success: (() -> Void)?,
                                    fail: ApiFailure?) {
        DinCore.homeDelegate?.dinCoreHomeWillChange(to: homeID)

        /// 默认先置空，等待请求服务器获取最新的UDP地址。
        /// 这样做是为了防止在获取目标地址之前，接入默认的地址，而默认地址能提供对应的接口功能，从而IPC等相关设备注册好了对应的KCP和UDP沟通渠道，这个时候再切换到目标地址，就会有设备离线，请求无应答状况，涉及到kcp通讯使用的EndID，secret等等数据
        DinCore.kUdpURL = ""

        guard homeID.count > 0 else {
            DinCore.user?.setCurHome(nil, replace: true, complete: { _ in
                homeDidSet?()
                DinCore.homeDelegate?.dinCoreHomeDidUpdate()
                DispatchQueue.main.async {
                    success?()
                }
            })
            return
        }
        // 检查是否存在于家庭列表中
        for home in DinCore.user?.homes ?? [] where homeID == home.id {
            // 如果存在，先把当前家庭设置为缓存的一个，并告诉上层，然后再请求家庭信息
            // 仅仅把当前家庭设置为命中的缓存家庭，待请求详细信息后，再使用新家庭
            DinCore.user?.setCurHome(home, replace: false, complete: { _ in
                homeDidSet?()
                DispatchQueue.main.async {
                    // 请求家庭详细信息
                    loadHomeDetail(homeID: homeID, success: success, fail: fail)
                }
            })
            return
        }
        
        // 如果没有存在家庭列表中，把家庭列表的第一个家庭，设置到当前家庭（如果无，则为nil）
        if let firstHome = DinCore.user?.homes?.first {
            DinCore.user?.setCurHome(firstHome, replace: true, complete: { _ in
                homeDidSet?()
                DispatchQueue.main.async {
                    // 请求家庭详细信息
                    loadHomeDetail(homeID: homeID, success: success, fail: fail)
                }
            })
        } else {
            DinCore.user?.setCurHome(nil, replace: true, complete: { _ in
                homeDidSet?()
                DinCore.homeDelegate?.dinCoreHomeDidUpdate()
                DispatchQueue.main.async {
                    success?()
                }
            })
        }
    }

    /// 切换自定义规则家庭
    /// 在家庭列表中寻找需要切换的家庭，如果有，先设置缓存再请求服务器获取家庭详情
    /// - Parameters:
    ///   - homeID: 家庭ID
    ///   - homeDidSet: 在家庭列表中找到了，完成缓存的预设（如果没有，找家庭列表，家庭列表没有，置空直接返回，不请求详情），紧接着去请求家庭详情
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func switchToThirdPartyHome(homeID: String,
                                              homeDidSet: (() -> Void)?,
                                              success: (() -> Void)?,
                                              fail: ApiFailure?) {
        DinCore.homeDelegate?.dinCoreHomeWillChange(to: homeID)

        /// 默认先置空，等待请求服务器获取最新的UDP地址。
        /// 这样做是为了防止在获取目标地址之前，接入默认的地址，而默认地址能提供对应的接口功能，从而IPC等相关设备注册好了对应的KCP和UDP沟通渠道，这个时候再切换到目标地址，就会有设备离线，请求无应答状况，涉及到kcp通讯使用的EndID，secret等等数据
        DinCore.kUdpURL = ""

        guard homeID.count > 0 else {
            DinCore.user?.setCurHome(nil, replace: true, complete: { _ in
                homeDidSet?()
                DinCore.homeDelegate?.dinCoreHomeDidUpdate()
                DispatchQueue.main.async {
                    success?()
                }
            })
            return
        }

        // 检查是否存在于家庭列表中
        for home in DinCore.user?.homes ?? [] where homeID == home.id {
            // 如果存在，先把当前家庭设置为缓存的一个，并告诉上层，然后再请求家庭信息
            // 仅仅把当前家庭设置为命中的缓存家庭，待请求详细信息后，再使用新家庭
            DinCore.user?.setCurHome(home, replace: false, complete: { _ in
                homeDidSet?()
                DispatchQueue.main.async {
                    // 请求家庭详细信息
                    loadHomeDetail(homeID: homeID, success: success, fail: fail)
                }
            })
            return
        }

        DinCore.user?.setCurHome(nil, replace: true, complete: { _ in
            homeDidSet?()
            DinCore.homeDelegate?.dinCoreHomeDidUpdate()
            DispatchQueue.main.async {
                success?()
            }
        })
    }

    /// 设置家庭缓存数据，不请求服务器
    /// 在家庭列表中寻找需要切换的家庭，如果有，设置缓存
    /// - Parameters:
    ///   - homeID: 家庭ID
    ///   - withNotify: 是否需要通知上层 用户当前家庭数据改变 curHomeChangedObservable
    ///   - homeDidSet: 完成回调
    public static func setCacheHome(homeID: String,
                                    withNotify notify: Bool = true,
                                    homeDidSet: (() -> Void)?) {
        DinCore.homeDelegate?.dinCoreHomeWillChange(to: homeID)
        
        guard homeID.count > 0 else {
            DinCore.user?.setCurHome(nil, replace: true, complete: { _ in
                if notify {
                    DinCore.homeDelegate?.dinCoreHomeDidUpdate()
                }
                homeDidSet?()
            })
            return
        }

        // 检查是否存在于家庭列表中
        for home in DinCore.user?.homes ?? [] where homeID == home.id {
            // 如果存在，先把当前家庭设置为缓存的一个，并告诉上层，然后再请求家庭信息
            // 仅仅把当前家庭设置为命中的缓存家庭，待请求详细信息后，再使用新家庭
            DinCore.user?.setCurHome(home, replace: false, complete: { _ in
                if notify {
                    DinCore.homeDelegate?.dinCoreHomeDidUpdate()
                }
                homeDidSet?()
            })
            return
        }

        // 如果没有存在家庭列表中，把家庭列表的第一个家庭，设置到当前家庭（如果无，则为nil）
        DinCore.user?.setCurHome(DinCore.user?.homes?.first, replace: true, complete: { _ in
            if notify {
                DinCore.homeDelegate?.dinCoreHomeDidUpdate()
            }
            homeDidSet?()
        })
    }

    /// 同步家庭数据，如果服务器有响应，新建一个新的DinHome来替换旧的模型
    /// - Parameters:
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func loadHomeDetail(homeID: String, success: (() -> Void)?, fail: ApiFailure?) {
        // 请求家庭详细信息
        DinCore.getHomeDetailInfo(homeID: homeID) { home in
            DinCore.user?.setCurHome(home, replace: false, complete: { _ in
                DispatchQueue.main.async {
                    DinCore.homeDelegate?.dinCoreHomeDidUpdate()
                    success?()
                }
            })
        } fail: { error in
            fail?(error)
        }
    }

    public static func checkIfOnlyAdmin(homeID: String, success: ((Bool) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.checkIfOnlyAdmin(homeID: homeID)
        DinHttpProvider.request(request) { result in
            if let returnResult = result, let isOnlyAdmin = returnResult["is_only_admin"] as? Bool {
                success?(isOnlyAdmin)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func forceDeleteHome(homeID: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.forceDeleteHome(homeID: homeID)
        DinHttpProvider.request(request) { result in
            DinCore.user?.deleteHome(withID: homeID)
            if homeID == DinCore.user?.curHome?.id, let firstHome = DinCore.user?.homes?.first {
                DinCore.switchToHome(homeID: firstHome.id, homeDidSet: nil, success: nil, fail: nil)
            } else if DinCore.user?.homes?.count ?? 0 == 0 {
                DinCore.switchToHome(homeID: "", homeDidSet: nil, success: nil, fail: nil)
            }
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func addThirdPartyIPC(name: String, homeID: String, data: [String: Any], success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinThirdPartyCameraRequest.addThirdPartyIPC(name: name, homeID: homeID, data: data)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func deleteThirdPartyIPC(
        pid: String,
        homeID: String,
        provider: String,
        success: (() -> Void)?,
        fail: ApiFailure?
    ) {
        let request = DinThirdPartyCameraRequest.deleteThirdPartyIPC(
            pid: pid,
            homeID: homeID,
            provider: provider
        )
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func getThirdPartyIPCServiceSetting(pid: String, homeID: String, provider: String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let request = DinThirdPartyCameraRequest.getThirdPartyIPCServiceSetting(pid: pid, homeID: homeID, provider: provider)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let serviceSettingDict = returnDict["ipc_service"] as? [String: Any] {
                success?(serviceSettingDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func saveThirdPartyIPCServiceSetting(pid: String, homeID: String, provider: String, alertMode: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinThirdPartyCameraRequest.saveThirdPartyIPCServiceSetting(pid: pid, homeID: homeID, provider: provider, alertMode: alertMode)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func getThirdPartyIPCList(homeID: String, provider: [String], pageSize: Int, addTime: Int64, success: (([[String: Any]]) -> Void)?, fail: ApiFailure?) {
        let request = DinThirdPartyCameraRequest.getThirdPartyIPCList(homeID: homeID, provider: provider, pageSize: pageSize, addTime: addTime)
        DinHttpProvider.request(request) { result in
            if let returnResult = result, let ipcs = returnResult["list"] as? [[String: Any]] {
                success?(ipcs)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func searchThirdPartyIPCList(homeID: String, pids: [[String: Any]], success: (([[String: Any]]) -> Void)?, fail: ApiFailure?) {
        let request = DinThirdPartyCameraRequest.searchThirdPartyIPCList(homeID: homeID, pids: pids)
        DinHttpProvider.request(request) { result in
            if let returnResult = result, let ipcs = returnResult["list"] as? [[String: Any]] {
                success?(ipcs)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func renameThirdPartyIPC(
        homID: String,
        pid: String,
        name: String,
        provider: String,
        success: (() -> Void)?,
        fail: ApiFailure?
    ) {
        let request = DinThirdPartyCameraRequest.renameThirdPartyIPC(homID: homID, pid: pid, name: name, provider: provider)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }

    }

    public static func updateThirdPartyIPCInfo(pid: String, homeID: String, data: [String: Any], success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinThirdPartyCameraRequest.updateThirdPartyIPCInfo(pid: pid, homeID: homeID, data: data)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func countCam(byProviders providers: [String], homeID: String, success: (([[String: Any]]) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.countCam(providers: providers, homeID: homeID)
        DinHttpProvider.request(request) { result in
            if let returnResult = result, let camsResult = returnResult["ipc_totals"] as? [[String: Any]] {
                success?(camsResult)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func countCamAndDoorBell(homeID: String, success: ((Int, Int, Int) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.countCamAndDoorBell(homeID: homeID)
        DinHttpProvider.request(request) { result in
            if let returnResult = result {
                let cams = returnResult["ipc_total"] as? Int ?? 0
                let doorBells = returnResult["door_dell_total"] as? Int ?? 0
                let chimes = returnResult["chime_total"] as? Int ?? 0
                success?(cams, doorBells, chimes)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func countBmt(homeID: String, success: ((Int, Int, Int, Int, Int, Int) -> Void)?, fail: ApiFailure?) {
        let request = DinStorageBatteryRequest.getBatteryCellsCount(.init(homeID: homeID, models: [
            DinStorageBatteryHP5000.provider,
            DinStorageBatteryHP5001.provider,
            DinStorageBatteryPowerCore20.provider,
            DinStorageBatteryPowerCore30.provider,
            DinStorageBatteryPowerStore.provider,
            DinStorageBatteryPowerPulse.provider,
        ]))
        DinHttpProvider.request(request) { result in
            if let returnResult = result?["models"] as? [[String: Any]] {
                var count5000 = 0
                var count5001 = 0
                var countPowerCore20 = 0
                var countPowerCore30 = 0
                var countPowerStore = 0
                var countPowerPulse = 0
                returnResult.forEach { countModel in
                    if let model = countModel["model"] as? String{
                        if model == DinStorageBatteryHP5000.provider {
                            count5000 = countModel["count"] as? Int ?? 0
                        }
                        if model == DinStorageBatteryHP5001.provider {
                            count5001 = countModel["count"] as? Int ?? 0
                        }
                        if model == DinStorageBatteryPowerCore20.provider {
                            countPowerCore20 = countModel["count"] as? Int ?? 0
                        }
                        if model == DinStorageBatteryPowerCore30.provider {
                            countPowerCore30 = countModel["count"] as? Int ?? 0
                        }
                        if model == DinStorageBatteryPowerStore.provider {
                            countPowerStore = countModel["count"] as? Int ?? 0
                        }
                        if model == DinStorageBatteryPowerPulse.provider {
                            countPowerPulse = countModel["count"] as? Int ?? 0
                        }
                    }
                }
                success?(count5000, count5001, countPowerCore20, countPowerCore30, countPowerStore, countPowerPulse)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }


    }

    public static func countContact(homeID: String, success: ((Int, [DinMemberProfile]) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.countContact(homeID: homeID)
        DinHttpProvider.request(request) { result in
            if let total = result?["total"] as? Int, let membersArray = result?["avatars"] as? [[String: Any]] {
                let membersOptional = [DinMemberProfile].deserialize(from: membersArray)
                var members: [DinMemberProfile] = []
                membersOptional?.forEach {
                    if let member = $0 {
                        members.append(member)
                    }
                }
                success?(total, members)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }

    }

#if ENABLE_DINCORE_LIVESTREAMING
    public static func renameIPC(pid: String, homeID: String, name: String, provider: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.renameDevice(
            homeID: homeID,
            deviceID: pid,
            newName: name,
            provider: provider
        )
        DinHttpProvider.request(
            request,
            success: { _ in
                let categoryID = DinLiveStreaming.transformIPCProviderToAccessoryManageID(provider)
                if let devices = DinCore.user?.curHome?.getDevices(withCategoryID: categoryID), let device = devices.first(where: { $0.id == pid }), let camera = device as? DinLiveStreamingOperator {
                    camera.liveStreamingControl.rename(name) {
                        var reason: DevicesUpdateReason = .renameDevices(deviceId: pid)
                        // 用个子线程推送给上层，以防被卡住
                        DispatchQueue.global().async {
                            DinCore.homeDelegate?.dinCoreHomeDevicesDidUpdate(categoryID: categoryID, reason: reason)
                        }
                    }
                }
                success?()
            },
            fail: { error in fail?(error) }
        )
    }
#endif

#if ENABLE_DINCORE_PANEL
    public static func deletePanel(panelID: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.deletePanel(panelID: panelID)
        DinHttpProvider.request(request) { _ in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
#endif

    public static func getFilteredEvents(timestamp: Int64, homeID: String, filters: [Int], success: (([[String: Any]]) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.getFilteredEvents(timestamp: timestamp, homeID: homeID, filters: filters)
        DinHttpProvider.request(request) { result in
            if let returnResult = result, let events = returnResult["event_list"] as? [[String: Any]] {
                success?(events)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }

    }

    public static func getFilteredEventsOld(panelID: String, timestamp: Int64, homeID: String, filters: [Int], success: (([[String: Any]]) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.getFilteredEventsOld(panelID: panelID, timestamp: timestamp, homeID: homeID, filters: filters)
        DinHttpProvider.request(request) { result in
            if let returnResult = result, let events = returnResult["eventlist"] as? [[String: Any]] {
                success?(events)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }

    }

#if ENABLE_DINCORE_LIVESTREAMING
    public static func deleteDinCamera(inHome homeID: String, cameraID: String, provider: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.deleteDevice(
            homeID: homeID,
            deviceID: cameraID,
            provider: provider
        )
        DinHttpProvider.request(request) { _ in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func listMotionRecords(homeID: String, providers: [String], pageSize: Int, addTime: Int64, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.listMotionRecords(homeID: homeID, providers: providers, pageSize: pageSize, addTime: addTime)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func deleteMotionRecords(homeID: String, recordIDs: [String], success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.deleteMotionRecords(homeID: homeID, recordIDs: recordIDs)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func getIPCVideoURL(homeID: String, recordID: String, success: ((String) -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.getIPCVideoURL(homeID: homeID, recordID: recordID)
        DinHttpProvider.request(request) { result in
            if let urlString = result?["url"] as? String {
                success?(urlString)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func listMotionDetectEvents(
        homeID: String,
        providers: [String],
        pageSize: Int,
        addTime: Int64,
        success: (([[String: Any]]) -> Void)?,
        fail: ApiFailure?
    ) {
        let request = DinLiveStreamingRequest.listMotionDetectEvents(homeID: homeID, providers: providers, pageSize: pageSize, addTime: addTime)
        DinHttpProvider.request(
            request,
            success: { response in
                if let result = response?["records"] as? [[String: Any]] {
                    success?(result)
                } else {
                    fail?(DinNetwork.Error.modelConvertFail("DinHome"))
                }
            },
            fail: { error in
                fail?(error)
            }
        )
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func getMotionDetectEventRecordCount(homeID: String, eventID: String, success: ((Int) -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.getMotionDetectEventRecordCount(homeID: homeID, eventID: eventID)
        DinHttpProvider.request(
            request,
            success: { response in
                if let result = response?["total"] as? Int {
                    success?(result)
                } else {
                    fail?(DinNetwork.Error.modelConvertFail("DinHome"))
                }
            },
            fail: { error in
                fail?(error)
            }
        )
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func listMotionDetectEventRecords(homeID: String, eventID: String, startIndex: Int, pageSize: Int, success: (([[String: Any]]) -> Void)?, fail: ApiFailure?) {
        let request  = DinLiveStreamingRequest.listMotionDetectEventRecords(homeID: homeID, eventID: eventID, startIndex: startIndex, pageSize: pageSize)
        DinHttpProvider.request(
            request,
            success: { response in
                if let result = response?["records"] as? [[String: Any]] {
                    success?(result)
                } else {
                    fail?(DinNetwork.Error.modelConvertFail("DinHome"))
                }
            },
            fail: { error in
                fail?(error)
            }
        )
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func deleteMotionDetectEvent(homeID: String, eventIDs: [String], success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.deleteMotionDetectEvent(homeID: homeID, eventIDs: eventIDs)
        DinHttpProvider.request(
            request,
            success: { _ in success?() },
            fail: fail
        )
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func getLatestTriggerMotionDetectTime(homeID: String, startTime: TimeInterval, endTime: TimeInterval, success: (([[String: Any]]) -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.getLatestTriggerMotionDetectTime(homeID: homeID, startTime: startTime, endTime: endTime)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let ipcsData = returnDict["ipcs"] as? [[String: Any]] {
                success?(ipcsData)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func getPeriodMotionDetectEvents(cameraIDs: [String], homeID: String, startTime: TimeInterval, endTime: TimeInterval, success: (([[String: Any]]) -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.getPeriodMotionDetectEvents(cameraIDs: cameraIDs, homeID: homeID, startTime: startTime, endTime: endTime)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let eventsData = returnDict["events"] as? [[String: Any]] {
                success?(eventsData)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func getMotionDetectVideos(eventID: String, eventStartTime: TimeInterval, homeID: String, limit: Int, ipcId: String, success: (([[String: Any]]) -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.getMotionDetectVideos(eventID: eventID, eventStartTime: eventStartTime, homeID: homeID, limit: limit, ipcId: ipcId)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let videosData = returnDict["videos"] as? [[String: Any]] {
                success?(videosData)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func getMotionDetectEventDates(homeID: String, timezone: String, success: (([String]) -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.getMotionDetectEventDates(homeID: homeID, timezone: timezone)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let datesData = returnDict["dates"] as? [String] {
                success?(datesData)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func getMotionDetectEventCovers(homeID: String, eventIDs: [String], success: (([[String: String]]) -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.getMotionDetectEventCovers(homeID: homeID, eventIDs: eventIDs)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let resultDicts = returnDict["covers"] as? [[String: String]] {
                success?(resultDicts)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func getLastTriggeredTimeByCamId(homeID: String, camId: String, success: ((TimeInterval) -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.getLastTriggeredTimeByCamId(homeID: homeID, camId: camId)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let timestamp = returnDict["time"] as? TimeInterval {
                success?(timestamp)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }

    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func renameVideoDoobell(pid: String, homeID: String, name: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.renameDevice(
            homeID: homeID,
            deviceID: pid,
            newName: name,
            provider: DinVideoDoorbell.categoryID
        )
        DinHttpProvider.request(
            request,
            success: { _ in success?() },
            fail: { error in fail?(error) }
        )
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func deleteVideoDoorbell(inHome homeID: String, deviceID: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.deleteDevice(
            homeID: homeID,
            deviceID: deviceID,
            provider: DinVideoDoorbell.categoryID
        )
        DinHttpProvider.request(request) { _ in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
#endif

#if ENABLE_DINCORE_LIVESTREAMING
    public static func getIPCVersions(providers: [String], success: (([String: Any]?) -> Void)?, fail: ApiFailure?) {
        let request = DinLiveStreamingRequest.getVersions(providers: providers)
        DinHttpProvider.request(
            request,
            success: { response in
                success?(response)
            },
            fail: { error in
                fail?(error)
            }
        )
    }
#endif

    /// 新建自定义家庭
    /// - Parameters:
    ///   - bindID: 和家庭绑定的目标ID（比较宽泛，第一个有这样需求的是旧的CAWA系统里面的主机绑定新的HelioPro家庭，所以这里的bindID就是主机ID）
    ///   - bindToken: 和家庭绑定的目标操作token
    ///   - homeInfo: 家庭的相关设置信息
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func createThirdPartyHome(bindID: String, bindToken: String, homeInfo: DinHomeRequestInfo, success: ((DinHome) -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.createThirdPartyHome(bindID: bindID, bindToken: bindToken, homeInfo: homeInfo)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let homeID = returnDict["home_id"] as? String {
                let newHome = DinHome()
                newHome.id = homeID
                newHome.name = homeInfo.homeName
                DinCore.user?.addHomes([newHome])
                success?(newHome)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    public static func deleteThirdPartyMember(homeID: String, userID: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.deleteThirdPartyMember(homeID: homeID, userID: userID)
        DinHttpProvider.request(request) { result in
            // 删除自己
            if userID == DinCore.user?.id {
                // 删除对应家庭
                DinCore.user?.deleteHome(withID: homeID)
                // 直接置空，不默认选择用户第一个家庭连接，等第三方自动调用连接
                DinCore.switchToHome(homeID: "", homeDidSet: nil, success: nil, fail: nil)
            }
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func deleteThirdPartyHome(homeID: String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinHomeRequest.deleteThirdPartyHome(homeID: homeID)
        DinHttpProvider.request(request) { result in
            DinCore.user?.deleteHome(withID: homeID)
            // 直接置空，不默认选择用户第一个家庭连接，等第三方自动调用连接
            DinCore.switchToHome(homeID: "", homeDidSet: nil, success: nil, fail: nil)
            success?()
        } fail: { error in
            fail?(error)
        }
    }

    public static func renameStorageBattery(pid: String, homeID: String, name: String, provider: String, success: (() -> Void)?, fail: ApiFailure?) {
        let params = DinStorageBatteryRequest.RenameParameters(homeID: homeID,
                                                               deviceID: pid,
                                                               model: provider,
                                                               name: name)
        let request = DinStorageBatteryRequest.rename(params)
        DinHttpProvider.request(
            request,
            success: { _ in success?() },
            fail: { error in fail?(error) }
        )
    }

    public static func deleteDinStorageBattery(inHome homeID: String, storageBatteryID: String, manageTypeID: String, provider: String, success: (() -> Void)?, fail: ApiFailure?) {
        let params = DinStorageBatteryRequest.DeleteDeviceParameters(homeID: homeID,
                                                                     deviceID: storageBatteryID,
                                                                     model: provider)
        let request = DinStorageBatteryRequest.deleteDevice(params)
        DinHttpProvider.request(request) { _ in
            // 从缓存中删除设备
            DinCore.user?.curHome?.removeDevice(storageBatteryID, manageTypeID: manageTypeID, success: success, fail: success)
        } fail: { error in
            let errorCode = (error as? DinNetwork.Error)?.errorCode ?? -1
            // 家庭找不到该设备时，更新设备缓存
            if errorCode == -77 {
                DinCore.user?.curHome?.setDeviceAsDeleted(storageBatteryID, manageTypeID: manageTypeID, success: {
                    fail?(error)
                }, fail: {
                    fail?(error)
                })
            } else {
                fail?(error)
            }
        }
    }

    public static func getDailyMemoriesVideoURL(
        atHome homeID: String,
        recordID: String,
        success: (([String: Any]) -> Void)?,
        fail: ApiFailure?
    ) {
        let request = DinHomeRequest.getDailyMemoriesVideoURL(homeID: homeID, recordID: recordID)
        DinHttpProvider.request(request) { result in
            if let returnResult = result {
                success?(returnResult)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }

    // 生成移交设备二维码
    public static func generateDeviceTransferQRCode(homeID: String, success: ((String) -> Void)?, fail: ApiFailure?) {
        let parameters = DinFixRequest.GenHomeQrcodeParameters(homeID: homeID)
        let request = DinFixRequest.genHomeQrcode(parameters)
        DinHttpProvider.request(request) { result in
            if let returnDict = result, let code = returnDict["qr_code"] as? String {
                success?(code)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    // 安装人员转移设备
    public static func operatorTransfer(bmtId: String, model: String, qrCode: String, ticketId: String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let parameters = DinFixRequest.OperatorTransferParameters(bmtId: bmtId, model: model, qrCode: qrCode, ticketId: ticketId)
        let request = DinFixRequest.operatorTransfer(parameters)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func saveFamilyContractInfo(data: [String: Any], homeID : String, success: (() -> Void)?, fail: ApiFailure?) {
        guard let iban = data["IBAN"] as? String,
              let cardHolder = data["cardholder"] as? String,
              let city = data["city"] as? String,
              let companyName = data["company_name"] as? String,
              let country = data["country_code"] as? String,
              let electSupplier = data["electricity_supplier"] as? String,
              let electSupplierID = data["electricity_supplier_id"] as? String,
              let emailAddress = data["email_address"] as? String,
              let euVatNum = data["eu_vat_number"] as? String,
              let name = data["name"] as? String,
              let sign = data["sign"] as? String,
              let streetNameAndNum = data["street_name_and_number"] as? String,
              let type = data["type"] as? Int,
              let zipCode = data["zip_code"] as? String
        else {
            fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            return
        }
        let parameters = DinStorageBatteryRequest.ContractInfoParameters(homeID: homeID, data: data)
            
        let request = DinStorageBatteryRequest.saveFamilyContractInfo(parameters)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func saveR2FamilyContractInfo(data: [String: Any], homeID : String, source: Int, success: (() -> Void)?, fail: ApiFailure?) {
        guard let iban = data["IBAN"] as? String,
              let cardHolder = data["cardholder"] as? String,
              let city = data["city"] as? String,
              let companyName = data["company_name"] as? String,
              let country = data["country_code"] as? String,
              let electSupplier = data["electricity_supplier"] as? String,
              let electSupplierID = data["electricity_supplier_id"] as? String,
              let emailAddress = data["email_address"] as? String,
              let euVatNum = data["eu_vat_number"] as? String,
              let name = data["name"] as? String,
              let sign = data["sign"] as? String,
              let streetNameAndNum = data["street_name_and_number"] as? String,
              let type = data["type"] as? Int,
              let zipCode = data["zip_code"] as? String
        else {
            fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            return
        }
        let parameters = DinStorageBatteryRequest.ContractR2InfoParameters(homeID: homeID, data: data, source: source)
            
        let request = DinStorageBatteryRequest.saveR2FamilyContractInfo(parameters)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func getFamilyContractInfo(homeID : String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let request = DinStorageBatteryRequest.getFamilyContractInfo(homeID)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func updateBalanceContractData(homeID : String, success: (() -> Void)?, fail: ApiFailure?) {
        let request = DinStorageBatteryRequest.updateBalanceContractData(homeID)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func getQNUploadToken(success: ((String) -> Void)?, fail: ApiFailure?) {
        // 先把头像上传到七牛，再把七牛返回的地址返回到服务器
        let target = DinUploadRequest.getUploadToken
        DinHttpProvider.request(target) { (result) in
            if let returnDict = result, let temp = returnDict["token"] as? String {
                let token = temp.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                success?(token)
            } else {
                fail?(DinNetwork.Error.noDataReturn(""))
            }
        } fail: { (error) in
            fail?(error)
        }
    }
    
    public static func getR2UploadToken(_ data: Data, fileName: String, type: DinR2UploadType, success: ((String, String) -> Void)?, fail: ApiFailure?) {
        // 先把文件信息上传到服务器，再把返回的token上传到R2
        
        let fileInfo = DinFileUploadManager.getAndPrintFileInfo(data: data, mimeType: "image/png")
        let parameters = DinR2FileForm(
            contentLength: fileInfo.size,
            contentType: fileInfo.mimeType,
            fileExtension: "",
            uploadtype: type,
            homeID: DinCore.user?.curHome?.id ?? "",
            fileName: fileName)
        
        let target = DinUploadRequest.getR2Toekn(parameters)
        DinHttpProvider.request(target) { (result) in
            if let returnDict = result, let temp = returnDict["token"] as? String, let key = returnDict["key"] as? String {
                let token = temp.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                success?(token, key)
            } else {
                fail?(DinNetwork.Error.noDataReturn(""))
            }
        } fail: { (error) in
            fail?(error)
        }
    }
    
    
    public static func listBMTCoutries(success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let request = DinStorageBatteryRequest.getRegionList
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
        
    }
    
    public static func listRegionElectricitySupplier(countryCode: String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let parameters = DinStorageBatteryRequest.GetRegionElectricitySupplierListV3Parameters(countryCode: countryCode, homeID: DinCore.user?.curHome?.id ?? "")
        let request = DinStorageBatteryRequest.getRegionElectricitySupplierListV3(parameters)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
        
    }
    
    public static func terminateBalanceContract(homeID: String, sign: String, success: (() -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.TeminateBalanceContactParameters(homeID: homeID, sign: sign)
        let request = DinStorageBatteryRequest.terminateBalanceContract(paramters)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func updateBalanceContractElectricityContract(electricityContractName: String, electricityContract: String, homeID : String, success: (() -> Void)?, fail: ApiFailure?) {
        let parameters = DinStorageBatteryRequest.UpdateElectricityContractParameters(homeID: homeID, electricityContractName: electricityContractName, electricityContract: electricityContract)
        let request = DinStorageBatteryRequest.updateElectricityContract(parameters)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
        
    }

    public static func terminateR2BalanceContract(homeID: String, sign: String, source: Int, success: (() -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.TeminateR2BalanceContactParameters(homeID: homeID, sign: sign, source: source)
        let request = DinStorageBatteryRequest.terminateR2BalanceContract(paramters)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func getBalanceContractRecords(homeID: String, createTime: Int64, pageSize: Int, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.GetBalanceContractRecordsParameter(createTime: createTime, homeID: homeID, pageSize: pageSize)
        let request = DinStorageBatteryRequest.getBalanceContractRecords(paramters)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func getgetBalanceContractRecordById(homeID: String, recordId: String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.GetBalanceContractRecordByIdParameter(homeID: homeID, recordId: recordId)
        let request = DinStorageBatteryRequest.GetBalanceContractRecordById(paramters)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func updateBalanceContractBank(cardholder: String, IBAN: String, homeID: String, password: String, success: (() -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.UpdateBalanceContractBankParameters(IBAN: IBAN, homeID: homeID, password: password, cardholder: cardholder)
        let request = DinStorageBatteryRequest.updateBalanceContractBank(paramters)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func checkStorageBatteryBalanceContractStatus(deviceID: String, homeID: String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.CheckStorageBatteryBalanceContractStatusParameters(deviceID: deviceID, homeID: homeID)
        let request = DinStorageBatteryRequest.checkStorageBatteryBalanceContractStatus(paramters)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func getBalanceContractUnsignTemplete(homeID: String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.GetBalanceContractUnsignTempleteParameter(homeID: homeID)
        let request = DinStorageBatteryRequest.getBalanceContractUnsignTemplete(paramters)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func getBalanceContractSignTemplete(countryCode: String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let request = DinStorageBatteryRequest.getBalanceContractSignTemplete(countryCode)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    /// 获取家庭定位地址（用于BMT AI模式配置）
    /// - Parameters:
    ///    - homeID: 家庭ID
    ///    - success: 成功回调
    ///    - fail: 失败回调
    public static func getHomeLocation(homeID: String, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.GetHomeLocationParameter(homeID: homeID)
        let request = DinStorageBatteryRequest.getHomeLocation(paramters)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    /// 保存家庭定位地址（用于BMT AI模式配置）
    /// - Parameters:
    ///    - homeID: 家庭ID
    ///    - latitude: 纬度
    ///    - longitude: 经度
    public static func saveHomeLocation(homeID: String, latitude: Double, longitude: Double, success: (() -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.SaveHomeLocationParameter(homeID: homeID, latitude: latitude, longitude: longitude)
        let request = DinStorageBatteryRequest.saveHomeLocation(paramters)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func getBalanceContractParticipationHoursList(homeID: String, createTime: Int64 = 0, pageSize: Int = 10, success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.GetBalanceContractParticipationHoursListParameter(createTime: createTime, homeID: homeID, pageSize: pageSize)
        let request = DinStorageBatteryRequest.getBalanceContractParticipationHoursList(paramters)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func addBalanceContractParticipationHours(homeID: String, allDay: Bool, start: String, end: String, repeatDays: [Int], success: (() -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.AddBalanceContractParticipationHoursParameter(homeID: homeID, allDay: allDay, start: start, end: end, repeatDays: repeatDays)
        let request = DinStorageBatteryRequest.addBalanceContractParticipationHours(paramters)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func updateBalanceContractParticipationHours(homeID: String, id: String, allDay: Bool, start: String, end: String, repeatDays: [Int], success: (() -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.UpdateBalanceContractParticipationHoursParameter(homeID: homeID, id: id, allDay: allDay, start: start, end: end, repeatDays: repeatDays)
        let request = DinStorageBatteryRequest.updateBalanceContractParticipationHours(paramters)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func deleteBalanceContractParticipationHours(homeID: String, id: String, success: (() -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.DeleteBalanceContractParticipationHoursParameter(homeID: homeID, id: id)
        let request = DinStorageBatteryRequest.deleteBalanceContractParticipationHours(paramters)
        DinHttpProvider.request(request) { result in
            success?()
        } fail: { error in
            fail?(error)
        }
    }
    
    public static func getIsTaskTimeInUpdatedRange(homeID: String, id: String, allDay: Bool, start: String, end: String, repeatDays: [Int], success: (([String: Any]) -> Void)?, fail: ApiFailure?) {
        let paramters = DinStorageBatteryRequest.getIsTaskTimeInUpdatedRangeParameters(homeID: homeID, id: id, allDay: allDay, start: start, end: end, repeatDays: repeatDays)
        let request = DinStorageBatteryRequest.getIsTaskTimeInUpdatedRange(paramters)
        DinHttpProvider.request(request) { result in
            if let returnDict = result {
                success?(returnDict)
            } else {
                fail?(DinNetwork.Error.modelConvertFail("DinHome"))
            }
        } fail: { error in
            fail?(error)
        }
    }
        
}
