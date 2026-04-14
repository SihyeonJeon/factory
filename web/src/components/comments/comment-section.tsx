"use client";

import { useState, useCallback, useRef } from "react";
import { useRealtimeComments } from "@/hooks/use-realtime-comments";
import type { EventComment } from "@/lib/types";

const MAX_BODY_LENGTH = 500;

interface CommentSectionProps {
  eventId: string;
  currentUserId: string | null;
  isHost: boolean;
}

/** Format relative time in Korean. */
function relativeTime(dateStr: string): string {
  const now = Date.now();
  const diff = now - new Date(dateStr).getTime();
  const seconds = Math.floor(diff / 1000);

  if (seconds < 60) return "방금 전";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}분 전`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}시간 전`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}일 전`;
  const months = Math.floor(days / 30);
  if (months < 12) return `${months}개월 전`;
  return `${Math.floor(months / 12)}년 전`;
}

function CommentItem({
  comment,
  canDelete,
  onDelete,
}: {
  comment: EventComment;
  canDelete: boolean;
  onDelete: (id: string) => void;
}) {
  const [isDeleting, setIsDeleting] = useState(false);

  const handleDelete = useCallback(async () => {
    if (isDeleting) return;
    setIsDeleting(true);
    onDelete(comment.id);
  }, [comment.id, isDeleting, onDelete]);

  return (
    <div className="flex gap-3 py-3">
      {/* Avatar */}
      <div
        className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-gray-200 text-xs font-medium text-gray-600"
        aria-hidden="true"
      >
        {comment.authorAvatar ? (
          <img
            src={comment.authorAvatar}
            alt=""
            className="h-8 w-8 rounded-full object-cover"
          />
        ) : (
          comment.authorName.charAt(0)
        )}
      </div>

      {/* Content */}
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-gray-900">
            {comment.authorName}
          </span>
          <span className="text-xs text-gray-400">
            {relativeTime(comment.createdAt)}
          </span>
        </div>
        <p className="mt-0.5 whitespace-pre-wrap break-words text-sm text-gray-700">
          {comment.body}
        </p>
      </div>

      {/* Delete button */}
      {canDelete && (
        <button
          type="button"
          onClick={handleDelete}
          disabled={isDeleting}
          className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg text-gray-300 transition-colors hover:bg-gray-100 hover:text-gray-500 disabled:opacity-50"
          aria-label="코멘트 삭제"
        >
          <svg
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <path d="M3 6h18" />
            <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" />
            <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" />
          </svg>
        </button>
      )}
    </div>
  );
}

export function CommentSection({
  eventId,
  currentUserId,
  isHost,
}: CommentSectionProps) {
  const { comments, isLoading } = useRealtimeComments(eventId);
  const [body, setBody] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const trimmedLength = body.trim().length;

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      if (isSubmitting || trimmedLength === 0 || trimmedLength > MAX_BODY_LENGTH)
        return;

      setIsSubmitting(true);
      setError(null);

      try {
        const res = await fetch("/api/comments", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ eventId, body: body.trim() }),
        });

        if (!res.ok) {
          const data = await res.json();
          if (res.status === 401) {
            window.location.href = `/login?next=/event/${eventId}`;
            return;
          }
          setError(data.error ?? "코멘트 등록에 실패했습니다");
          return;
        }

        setBody("");
        textareaRef.current?.focus();
      } catch {
        setError("네트워크 오류가 발생했습니다");
      } finally {
        setIsSubmitting(false);
      }
    },
    [body, eventId, isSubmitting, trimmedLength],
  );

  const handleDelete = useCallback(async (commentId: string) => {
    try {
      const res = await fetch(`/api/comments/${commentId}`, {
        method: "DELETE",
      });

      if (!res.ok) {
        const data = await res.json();
        setError(data.error ?? "코멘트 삭제에 실패했습니다");
      }
    } catch {
      setError("네트워크 오류가 발생했습니다");
    }
  }, []);

  return (
    <section aria-label="코멘트" className="space-y-4">
      <h2 className="text-base font-semibold text-gray-900">
        코멘트 {comments.length > 0 && (
          <span className="text-sm font-normal text-gray-400">
            {comments.length}
          </span>
        )}
      </h2>

      {/* Error message */}
      {error && (
        <p
          role="alert"
          className="rounded-lg bg-red-50 px-4 py-2 text-sm text-red-600"
        >
          {error}
        </p>
      )}

      {/* Comment list */}
      {isLoading ? (
        <div className="py-8 text-center text-sm text-gray-400">
          불러오는 중...
        </div>
      ) : comments.length === 0 ? (
        <div className="py-8 text-center text-sm text-gray-400">
          아직 코멘트가 없어요
        </div>
      ) : (
        <div className="divide-y divide-gray-100">
          {comments.map((comment) => (
            <CommentItem
              key={comment.id}
              comment={comment}
              canDelete={
                currentUserId !== null &&
                (comment.authorId === currentUserId || isHost)
              }
              onDelete={handleDelete}
            />
          ))}
        </div>
      )}

      {/* Input form — only for logged-in users */}
      {currentUserId && (
        <form onSubmit={handleSubmit} className="space-y-2">
          <div className="relative">
            <textarea
              ref={textareaRef}
              value={body}
              onChange={(e) => setBody(e.target.value)}
              placeholder="코멘트를 남겨보세요"
              maxLength={MAX_BODY_LENGTH}
              rows={2}
              className="w-full resize-none rounded-xl border border-gray-200 px-4 py-3 text-sm text-gray-900 placeholder:text-gray-400 focus:border-gray-400 focus:outline-none focus:ring-0"
            />
            <span
              className={`absolute bottom-2 right-3 text-xs ${
                trimmedLength > MAX_BODY_LENGTH * 0.9
                  ? "text-red-400"
                  : "text-gray-300"
              }`}
              aria-live="polite"
            >
              {trimmedLength}/{MAX_BODY_LENGTH}
            </span>
          </div>
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={
                isSubmitting ||
                trimmedLength === 0 ||
                trimmedLength > MAX_BODY_LENGTH
              }
              className="inline-flex h-10 min-w-[64px] items-center justify-center rounded-xl bg-gray-900 px-4 text-sm font-medium text-white transition-colors hover:bg-gray-800 disabled:cursor-not-allowed disabled:opacity-40"
            >
              {isSubmitting ? "등록 중..." : "등록"}
            </button>
          </div>
        </form>
      )}
    </section>
  );
}
