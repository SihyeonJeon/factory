"use client";

import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import type { EventFormData } from "@/lib/types";

interface EventDetailsFormProps {
  data: EventFormData;
  onUpdate: (partial: Partial<EventFormData>) => void;
}

export function EventDetailsForm({ data, onUpdate }: EventDetailsFormProps) {
  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold tracking-tight">모임 정보</h2>
        <p className="text-muted-foreground text-sm">
          기본 정보를 입력하세요
        </p>
      </div>

      <div className="mx-auto max-w-md space-y-4">
        <div className="space-y-2">
          <Label htmlFor="title">모임 이름</Label>
          <Input
            id="title"
            placeholder="예: 4월 러닝 아크 정기런"
            value={data.title}
            onChange={(e) => onUpdate({ title: e.target.value })}
            maxLength={100}
            autoFocus
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="datetime">날짜 및 시간</Label>
          <Input
            id="datetime"
            type="datetime-local"
            value={data.datetime}
            onChange={(e) => onUpdate({ datetime: e.target.value })}
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="location">장소</Label>
          <Input
            id="location"
            placeholder="예: 서울 성수동 카페"
            value={data.location}
            onChange={(e) => onUpdate({ location: e.target.value })}
            maxLength={100}
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="description">설명 (선택)</Label>
          <Textarea
            id="description"
            placeholder="모임에 대해 간단히 설명해주세요"
            value={data.description}
            onChange={(e) => onUpdate({ description: e.target.value })}
            rows={3}
            maxLength={500}
          />
        </div>

        <div className="flex items-center justify-between rounded-lg border p-4">
          <div>
            <Label htmlFor="hasFee" className="text-sm font-medium">
              참석비가 있나요?
            </Label>
            <p className="text-xs text-muted-foreground mt-0.5">
              게스트에게 회비 납부 의향을 확인합니다
            </p>
          </div>
          <button
            id="hasFee"
            type="button"
            role="switch"
            aria-checked={data.hasFee}
            onClick={() => onUpdate({ hasFee: !data.hasFee })}
            className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors ${
              data.hasFee ? "bg-violet-600" : "bg-gray-200"
            }`}
          >
            <span
              className={`pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow ring-0 transition-transform ${
                data.hasFee ? "translate-x-5" : "translate-x-0"
              }`}
            />
          </button>
        </div>
      </div>
    </div>
  );
}
