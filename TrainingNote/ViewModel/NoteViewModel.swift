//
//  NoteViewModel.swift
//  TrainingNote
//
//  Created by Mizuki Kubota on 2020/02/21.
//  Copyright © 2020 MizukiKubota. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct NoteViewModelInput {
    let slider: ControlProperty<Float>
    let stepper: ControlProperty<Double>
    let selectedDate: Date?
}

protocol NoteViewModelOutput {
    var exerciseDataDriver: Driver<[String]> { get }
    var weightDriver: Driver<String> { get }
    var repsDriver: Driver<String> { get }
    var secondsDriver: Driver<String> { get }
    var dateDriver: Driver<String> { get }
}

protocol NoteViewModelType {
    var outputs: NoteViewModelOutput? { get }
    func setup(input: NoteViewModelInput)
}

final class NoteViewModel: Injectable, NoteViewModelType {
    typealias Dependency = NoteModel

    private var model: NoteModel
    var outputs: NoteViewModelOutput?

    private let weightRelay = BehaviorRelay<Float>(value: 100)
    private let repsRelay = BehaviorRelay<Double>(value: 0)
    private var selectedDate: Date?

    private let disposeBag = DisposeBag()

    init(with dependency: Dependency) {
        model = dependency
        self.outputs = self
    }

    func setup(input: NoteViewModelInput) {

        input.slider
            .subscribe(onNext: { [weak self] slider in
                guard let self = self else { return }
                self.weightRelay.accept(slider)
            })
            .disposed(by: disposeBag)

        input.stepper
            .subscribe(onNext: { [weak self] stepper in
                guard let self = self else { return }
                self.repsRelay.accept(stepper)
            })
            .disposed(by: disposeBag)

        selectedDate = input.selectedDate

    }
}

extension NoteViewModel: NoteViewModelOutput {

    var exerciseDataDriver: Driver<[String]> {
        let dataRelay = BehaviorRelay<[String]>(value: [])
        model.outputs?.exerciseObservable
            .subscribe(onNext: { exercises in
                guard let exercises = exercises else { return }
                dataRelay.accept(exercises)
            })
            .disposed(by: disposeBag)

        return dataRelay.asDriver()
    }

    var weightDriver: Driver<String> {
        return weightRelay.asDriver().map {round($0)}.map {"\($0.description) kg"}
    }

    var repsDriver: Driver<String> {
        return repsRelay.asDriver().map {Int($0)}.map {"\($0.description) reps"}
    }

    var secondsDriver: Driver<String> {
        return Observable<Int>
            .interval(RxTimeInterval.milliseconds(10), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: 0)
            .map { String(format: "Interval: %02i:%02i:%02i", $0 / 6000, $0 / 100 % 60, $0 % 100) }
    }

    var dateDriver: Driver<String> {
        let dataRelay = BehaviorRelay<String>(value: "")

        let dateFormatter = DateFormatter()
        var dateString = String()
        // DateFormatter を使用して書式とローカルを指定する
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "M/d/yyyy", options: 0, locale: Locale(identifier: "en_US"))
        dateString = dateFormatter.string(from: selectedDate!)

        dataRelay.accept(dateString)
        return dataRelay.asDriver()
    }

}
