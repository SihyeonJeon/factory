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
            placeholder="예: 4월 러닝크루 정기런"
            value={data.title}
            onChange={(e) => onUpdate({ title: e.target.value })}
            maxLength={50}
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
      </div>
    </div>
  );
}
